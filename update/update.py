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

FABRIC_META = "https://meta.fabricmc.net/v2"
MODRINTH_API = "https://api.modrinth.com/v2"
CURSE_API = "https://api.curseforge.com/v1"
CURSE_CDN = "https://edge.forgecdn.net"


def cli():
    logging.basicConfig(level=logging.INFO)

    parser = argparse.ArgumentParser(description="Update minecraft server.")
    parser.add_argument("--game-version", metavar="VER", type=str)
    parser.add_argument("--update-game", action=argparse.BooleanOptionalAction)
    parser.add_argument("--dry-run", action=argparse.BooleanOptionalAction)
    args = parser.parse_args()
    main(args)


def main(args):
    with open("./config.json") as f:
        logging.info("loading config.json...")
        config = json.load(f)
    if not args.dry_run:
        logging.info("copying config.json to config.json.bak...")
        shutil.copy("./config.json", "./config.json.bak")
    update(args, config)
    if not args.dry_run:
        with open("./config.json", "w") as f:
            logging.info("saving config.json...")
            json.dump(config, f, indent=2)
            logging.info("done")


def update(args, config):
    ensure(config, "server", dict())
    update_server(args, config["server"])

    game_version = config["server"]["game"]["version"]
    ensure(config, "mods", [])
    update_mods(args, game_version, config["mods"])


def update_server(args, server_cfg):
    logging.info(f"updating minecraft...")
    ensure(server_cfg, "game", dict())
    if args.game_version is not None:
        server_cfg["game"]["version"] = args.game_version
    if args.update_game:
        game_versions = get_fabric_meta("versions/game")
        server_cfg["game"]["version"] = fabric_first_stable(game_versions)["version"]
    assert server_cfg["game"]["version"]


def update_mods(args, game_version, mods_cfg):
    modrinth = ModrinthAPI()
    curse = CurseAPI()
    for mod_cfg in mods_cfg:
        logging.info(f"updating mod '{mod_cfg['name']}'...")
        update_mod(args, modrinth, curse, game_version, mod_cfg)


def update_mod(args, modrinth, curse, game_version, mod_cfg):
    is_modrinth = "modrinthId" in mod_cfg
    is_curse = "curseForgeId" in mod_cfg
    assert is_modrinth or is_curse
    assert not (is_modrinth and is_curse)

    if "fakeGameVersion" in mod_cfg:
        game_version = mod_cfg["fakeGameVersion"]

    if is_modrinth:
        update_mod_modrinth(args, modrinth, game_version, mod_cfg)
    elif is_curse:
        update_mod_curse(args, curse, game_version, mod_cfg)


def update_mod_modrinth(args, modrinth, game_version, mod_cfg):
    modrinth_id = mod_cfg["modrinthId"]
    compatible_versions = modrinth.get(
        f'project/{modrinth_id}/version?loaders=["fabric"]&game_versions=["{game_version}"]'
    )

    ensure(mod_cfg, "versionTypeRegex", "release")
    ensure(mod_cfg, "filenameRegex", ".*")

    version_type_regex = re.compile(mod_cfg["versionTypeRegex"])

    def version_filter(version):
        if not version_type_regex.match(version["version_type"]):
            return False
        return True

    filtered_versions = filter(version_filter, compatible_versions)
    latest_version = modrinth_latest_version(filtered_versions)
    mod_cfg["version"] = latest_version["version_number"]

    filename_regex = re.compile(mod_cfg["filenameRegex"])

    def file_filter(file):
        if not filename_regex.match(file["filename"]):
            return False
        if "primaryFileOnly" in mod_cfg and mod_cfg["primaryFileOnly"]:
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
    assert len(file_list) >= 1
    mod_cfg["files"] = file_list


def update_mod_curse(args, curse, game_version, mod_cfg):
    curse_id = mod_cfg["curseForgeId"]
    FABRIC_TYPE = 4
    # no paginator support, at most 50 versions
    compatible_versions = curse.get(
        f"mods/{curse_id}/files?gameVersion={game_version}&modLoaderType={FABRIC_TYPE}"
    )["data"]

    ensure(mod_cfg, "versionTypeRegex", "release")

    version_type_regex = re.compile(mod_cfg["versionTypeRegex"])

    def version_filter(version):
        if not version["isAvailable"]:
            return False
        release_type = curse_release_type_to_str(version["releaseType"])
        if not version_type_regex.match(release_type):
            return False
        return True

    filtered_versions = filter(version_filter, compatible_versions)
    latest_version = curse_latest_version(filtered_versions)

    mod_cfg["version"] = latest_version["displayName"]
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
        download_url = f"{CURSE_CDN}/files/{id_part}/{filename}"
    mod_cfg["files"] = [
        {
            "filename": filename,
            "file": {
                "url": curse_quote_url(download_url),
                "sha1": hash["value"],
            },
        }
    ]


def ensure(d, key, default):
    if key not in d:
        d[key] = default


def get_url(url, **kw_args):
    logging.info(f"getting '{url}'...")
    response = requests.get(url, **kw_args)
    if response.status_code == 200:
        return response
    else:
        raise RuntimeError(f"failed to get f'{url}'")


def get_fabric_meta(resource):
    return get_url(f"{FABRIC_META}/{resource}").json()


def fabric_first_stable(response):
    return next(filter(lambda x: x["stable"], response))


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

    def headers(self):
        return {"x-api-key": self.api_key}

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


def curse_quote_url(url):
    result = urllib.parse.urlparse(url)
    quoted = result._replace(path=urllib.parse.quote(result.path))
    return urllib.parse.urlunparse(quoted)


if __name__ == "__main__":
    cli()
