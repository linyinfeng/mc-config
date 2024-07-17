import requests
import json
import argparse
import logging
import subprocess
import time
import iso8601
import re
import shutil
import os
import urllib.parse
import traceback
import natsort

FABRIC_META = "https://meta.fabricmc.net/v2"
MODRINTH_API = "https://api.modrinth.com/v2"
CURSE_API = "https://api.curseforge.com/v1"
CURSE_CDN = "https://edge.forgecdn.net"

KINDS = ["mod", "shaderPack", "resourcePack"]

CURSE_FORGE_GAME_ID_MC = 432
# curl -X GET 'https://api.curseforge.com/v1/categories?gameId=432&classesOnly=true' | jq
CURSE_FORGE_CLASS_ID = {
    "mod": 6,
    "shaderPack": 6552,
    "resourcePack": 12,
}
CURSE_FORGE_LOADER_ID = {
    "fabric": 4,
}

URL_PATTERNS = {
    "mod": {
        "modrinth": re.compile(
            "^https://modrinth.com/(?:mod|plugin|datapack)/(?P<slug>.*)$"
        ),
        "curseForge": re.compile(
            "^https://www.curseforge.com/minecraft/mc-mods/(?P<slug>.*)$"
        ),
    },
    "shaderPack": {
        "modrinth": re.compile("^https://modrinth.com/(?:shader)/(?P<slug>.*)$"),
        "curseForge": re.compile(
            "^https://www.curseforge.com/minecraft/shaders/(?P<slug>.*)$"
        ),
    },
    "resourcePack": {
        "modrinth": re.compile("^https://modrinth.com/(?:resourcepack)/(?P<slug>.*)$"),
        "curseForge": re.compile(
            "^https://www.curseforge.com/minecraft/texture-packs/(?P<slug>.*)$"
        ),
    },
}


def cli():
    parser = argparse.ArgumentParser(prog="update")
    parser.add_argument("--config", metavar="FILE", type=str, default="config.json")
    parser.add_argument("--lock-file", metavar="FILE", type=str, default="lock.json")
    parser.add_argument("--no-backup", action="store_true")
    parser.add_argument(
        "--log", metavar="LEVEL", type=str, default="INFO", help="log level"
    )
    parser.add_argument("--game-manifests", metavar="FILE", type=str)
    parser.add_argument("--dry-run", action=argparse.BooleanOptionalAction)
    args = parser.parse_args()

    log_level = args.log
    logging.basicConfig(level=log_level)

    try:
        main(args)
    except Exception as e:
        logging.error(e)
        logging.debug(traceback.format_exc())


def main(args):
    with open(args.config) as f:
        logging.info(f"loading '{args.config}'...")
        config = json.load(f)
    if not args.no_backup and not args.dry_run and os.path.isfile(args.lock_file):
        logging.info(f"copying '{args.lock_file}' to '{args.lock_file}.bak'...")
        shutil.copy(args.lock_file, f"{args.lock_file}.bak")
    apis = {"curseForge": CurseAPI(), "modrinth": ModrinthAPI()}
    preprocess(args, apis, config)
    lock = update(args, apis, config)
    if not args.dry_run:
        with open(args.lock_file, "w") as f:
            logging.info(f"saving config to '{args.lock_file}'...")
            json.dump(lock, f, indent=2)
            logging.info("done")


def preprocess(args, apis, config):
    modrinth = apis["modrinth"]
    curse = apis["curseForge"]

    for kind in KINDS:
        item_configs = config[kind + "s"]
        # bare strings are interpreted as urls
        for k, v in enumerate(item_configs):
            if isinstance(v, str):
                item_configs[k] = {"url": v}

        # extract name and slug/id from url
        # modrinth api support both id and slug
        # curseforge api requires project id
        for k, v in enumerate(item_configs):
            url = lookup(v, "url", None)
            if url is not None:
                logging.info(f"preprocessing {kind} url '{url}'...")

                exclusive_keys = ["name", "modrinthId", "curseForgeId"]
                for ek in exclusive_keys:
                    if lookup(v, ek, None) is not None:
                        raise RuntimeError(
                            f"'{ek}' will be automatically extracted from url"
                        )

                (website, slug) = parse_url(kind, url)

                if website == "modrinth":
                    project_info = modrinth.get(f"project/{slug}")
                    new_cfg = {
                        "name": f"{project_info['title']}",
                        f"{website}Id": project_info["id"],
                    }
                elif website == "curseForge":
                    search_results = curse.get(
                        f"mods/search?gameId={CURSE_FORGE_GAME_ID_MC}&classId={CURSE_FORGE_CLASS_ID[kind]}&slug={slug}"
                    )["data"]
                    # https://docs.curseforge.com/#search-mods
                    # query with classId and slug will result in a unique result
                    assert len(search_results) <= 1
                    if len(search_results) == 0:
                        raise RuntimeError(
                            f"unable to find {kind} on curseforge with slug '{slug}'"
                        )
                    search_result = search_results[0]
                    new_cfg = {
                        "name": search_result["name"],
                        f"{website}Id": search_result["id"],
                    }
                else:
                    raise RuntimeError("unreachable")

                item_configs[k].update(new_cfg)

        defaults = lookup(config, kind + "Defaults", dict())
        for k, item_config in enumerate(item_configs):
            for setting, default in defaults.items():
                if default is not None and lookup(item_config, setting, None) is None:
                    item_config[setting] = default


def parse_url(kind: str, url: str):
    """
    URL Examples:

        https://www.curseforge.com/minecraft/mc-mods/jei
        https://modrinth.com/mod/sodium
    """
    for website, pat in URL_PATTERNS[kind].items():
        match = pat.match(url)
        if match is not None:
            slug = match.group("slug")
            return (website, slug)
    raise RuntimeError(f"invalid {kind} URL: " + url)


def update(args, apis, config):
    lock = {"game": dict()}
    for kind in KINDS:
        lock[kind + "s"] = []

    update_game(args, config["game"], lock["game"])
    game_version = lock["game"]["version"]

    for kind in KINDS:
        loader = lookup(config, kind + "Loader", None)
        update_items(
            args, apis, game_version, kind, loader, config[kind + "s"], lock[kind + "s"]
        )
    return lock


def update_game(args, game_cfg, game_lock):
    version = lookup(game_cfg, "version", None)
    if version is not None:
        logging.info(f"version explicitly specified: '{version}'")
        game_lock["version"] = version
        return
    version_regex_str = lookup(game_cfg, "versionRegex", None)
    if version_regex_str is not None:
        version_regex = re.compile(version_regex_str)
        manifests_file = args.game_manifests
        with open(manifests_file) as f:
            logging.info(f"loading game manifests file '{manifests_file}'...")
            manifests = json.load(f)
        versions = manifests.keys()

        def version_filter(version):
            return version_regex.match(version)

        filtered_versions = [*filter(version_filter, versions)]
        # https://github.com/SethMMorton/natsort/wiki/Examples-and-Recipes#sorting-more-expressive-versioning-schemes
        sorted_versions = natsort.natsorted(
            filtered_versions, key=lambda x: x.replace(".", "~") + "z"
        )
        if len(sorted_versions) == 0:
            raise RuntimeError(f"can not find any valid game versions")
        logging.info(f"matched game versions: {sorted_versions}")
        version = sorted_versions[-1]
        logging.info(f"select game version: '{version}'")
        game_lock["version"] = version
        return
    raise RuntimeError("Neither game.version nor game.versionRegex is specified")


def update_items(args, apis, game_version, kind, loader, items_cfg, items_lock):
    for item_cfg in items_cfg:
        name = item_cfg["name"]
        logging.info(f"updating {kind}: '{name}'...")
        update_mod(args, name, apis, game_version, kind, loader, item_cfg, items_lock)


def update_mod(
    args, name, apis, global_game_version, kind, loader, item_cfg, items_lock
):
    manual = lookup(item_cfg, "manual", False)
    if manual:
        logging.info(f"skip {kind}: '{name}'")
        return

    is_modrinth = lookup(item_cfg, "modrinthId", False)
    is_curse = lookup(item_cfg, "curseForgeId", False)
    assert is_modrinth or is_curse or manual
    assert not (is_modrinth and is_curse)

    game_version = lookup(item_cfg, "fakeGameVersion", global_game_version)

    if is_modrinth:
        update_item_modrinth(
            args,
            apis["modrinth"],
            game_version,
            name,
            kind,
            loader,
            item_cfg,
            items_lock,
        )
    elif is_curse:
        update_item_curse(
            args,
            apis["curseForge"],
            game_version,
            name,
            kind,
            loader,
            item_cfg,
            items_lock,
        )


def update_item_modrinth(
    args, modrinth, game_version, name, kind, loader, item_cfg, items_lock
):
    modrinth_id = item_cfg["modrinthId"]
    if loader is not None:
        loader_params = f'&loaders=["{loader}"]'
    else:
        loader_params = f""
    compatible_versions = modrinth.get(
        f'project/{modrinth_id}/version?game_versions=["{game_version}"]{loader_params}'
    )

    version_type_regex = re.compile(lookup(item_cfg, "versionTypeRegex", "release"))

    def version_filter(version):
        return version_type_regex.match(version["version_type"])

    filtered_versions = [*filter(version_filter, compatible_versions)]
    if len(filtered_versions) == 0:
        raise RuntimeError(f"can not find any valid versions for {name}")
    latest_version = modrinth_latest_version(filtered_versions)
    item_cfg["version"] = latest_version["version_number"]

    filename_regex = re.compile(lookup(item_cfg, "filenameRegex", ".*"))

    def file_filter(file):
        if not filename_regex.match(file["filename"]):
            return False
        if lookup(item_cfg, "primaryFileOnly", False):
            if not file["primary"]:
                return False
        return True

    filtered_file = filter(file_filter, latest_version["files"])
    file_list = [
        *map(
            lambda f: {
                "filename": f["filename"],
                "file": {"url": f["url"], "sha512": f["hashes"]["sha512"]},
            },
            filtered_file,
        )
    ]
    if len(file_list) == 0:
        raise RuntimeError(f"can not find any valid files for {name}")
    items_lock.extend(file_list)


def update_item_curse(
    args, curse, game_version, name, kind, loader, item_cfg, items_lock
):
    curse_id = item_cfg["curseForgeId"]
    loader_type = lookup(CURSE_FORGE_LOADER_ID, loader, None)
    if loader_type is not None:
        loader_params = f"&modLoaderType={loader_type}"
    else:
        loader_params = f""
    # no paginator support, at most 50 versions
    compatible_versions = curse.get(
        f"mods/{curse_id}/files?gameVersion={game_version}{loader_params}"
    )["data"]

    version_type_regex = re.compile(lookup(item_cfg, "versionTypeRegex", "release"))

    def version_filter(version):
        if not version["isAvailable"]:
            return False
        release_type = curse_release_type_to_str(version["releaseType"])
        if not version_type_regex.match(release_type):
            return False
        return True

    filtered_versions = [*filter(version_filter, compatible_versions)]
    if len(filtered_versions) == 0:
        raise RuntimeError(f"can not find any valid versions for {name}")
    latest_version = curse_latest_version(filtered_versions)

    item_cfg["version"] = latest_version["displayName"]
    filename = latest_version["fileName"]
    ALGO_SHA1 = 1
    hash = [*filter(lambda h: h["algo"] == ALGO_SHA1, latest_version["hashes"])][0]
    if latest_version["downloadUrl"]:
        download_url = latest_version["downloadUrl"]
    else:
        logging.info('download url is "null", applying workaround...')
        file_id = str(latest_version["id"])
        SPLIT_SIZE = 4
        file_id_splitted = [
            file_id[i : i + SPLIT_SIZE] for i in range(0, len(file_id), SPLIT_SIZE)
        ]
        id_part = "/".join(file_id_splitted)
        download_url = f"{CURSE_CDN}/files/{id_part}/{urllib.parse.quote(filename)}"
    items_lock.append(
        {
            "filename": filename,
            "file": {
                "url": download_url,
                "sha1": hash["value"],
            },
        }
    )


def lookup(d, key, default):
    if key not in d or d[key] is None:
        return default
    else:
        return d[key]


def get_url(url, **kw_args):
    logging.debug(f"get '{url}'...")
    response = requests.get(url, **kw_args)
    if response.status_code == 200:
        return response
    else:
        raise RuntimeError(f"failed to get '{url}': {response.status_code}")


def nix_prefetch(url):
    logging.info(f"nix store prefetch-file '{url}'...")
    query = subprocess.run(
        ["nix", "store", "prefetch-file", "--json", url],
        stdout=subprocess.PIPE,
        check=True,
    )
    stdout = bytes.decode(query.stdout, errors="strict")
    result = json.loads(stdout)
    return {"url": url, "hash": result["hash"]}


def get_library_hash(library):
    [org, art, ver] = library["name"].split(":")
    filename = f"{art}-{ver}.jar"
    path = f"{org.replace('.','/')}/{art}/{ver}/{filename}"
    url = f"{library['url']}{path}"
    hash_url = f"{url}.sha512"
    hash = get_url(hash_url).text
    return {"name": library["name"], "file": {"url": url, "sha512": hash}}


class ModrinthAPI:
    def __init__(self):
        self.ratelimit_remaining = None
        self.ratelimit_reset = None
        self.last_request_time = None

    def get(self, resource):
        if self.ratelimit_remaining == 0:
            elapsed = time.time() - self.last_request_time
            wait_time = elapsed - self.ratelimit_reset + 1  # wait an extra second
            if wait_time > 0:
                logging.info(f"waiting for {wait_time} second(s)...")
                time.sleep(wait_time)
        response = get_url(f"{MODRINTH_API}/{resource}")
        if "x-ratelimit-remaining" in response.headers:
            self.ratelimit_remaining = int(response.headers["x-ratelimit-remaining"])
        if "x-ratelimit-reset" in response.headers:
            self.ratelimit_reset = int(response.headers["x-ratelimit-reset"])
        return response.json()


def modrinth_extract_date_from_version(version):
    return iso8601.parse_date(version["date_published"])


def modrinth_latest_version(versions):
    return sorted(versions, key=modrinth_extract_date_from_version, reverse=True)[0]


class CurseAPI:
    def __init__(self):
        self.api_key = os.environ.get("CURSEFORGE_API_KEY", "")
        if self.api_key == "":
            logging.info("no CurseForge api key")
        else:
            logging.info("CurseForge api key set")

    def headers(self):
        return {"Accept": "application/json", "x-api-key": self.api_key}

    def get(self, resource):
        response = get_url(f"{CURSE_API}/{resource}", headers=self.headers())
        return response.json()


def curse_release_type_to_str(n):
    if n == 1:
        return "release"
    elif n == 2:
        return "beta"
    elif n == 3:
        return "alpha"
    else:
        raise RuntimeError(f"invalid release type {n}")


def curse_extract_date_from_version(version):
    return iso8601.parse_date(version["fileDate"])


def curse_latest_version(versions):
    return sorted(versions, key=curse_extract_date_from_version, reverse=True)[0]


if __name__ == "__main__":
    cli()
