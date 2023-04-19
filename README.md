# mc-config

A simple Minecraft mod manager in nix (*fabric only*), based on [minecraft.nix](https://github.com/ninlives/minecraft.nix).

## Usage

Please refer to the template repository [mc-config-template](https://github.com/linyinfeng/mc-config-template), and read `flake.nix` and `example.nix`.

<details>
<summary>Legacy Style</summary>

Create a `config.in.json` containing the game and mod specifications, for example [config.in.json](https://github.com/linyinfeng/mc-config-template/blob/main/config.in.json).

Run `github:linyinfeng/mc-config#update` to create `config.json`, for example [config.json](https://github.com/linyinfeng/mc-config-template/blob/main/config.json).

```shell
$ nix run "github:linyinfeng/mc-config#update" -- --help
usage: update [-h] [--config-input FILE] [--config-output FILE] [--dry-run | --no-dry-run]

options:
  -h, --help            show this help message and exit
  --config-input FILE
  --config-output FILE
  --dry-run, --no-dry-run
```

Call `mc-config.lib.mkLaunchers` to get launchers.

```nix
contents = mc-config.lib.mkLaunchers pkgs {
    launcherConfig = lib.importJSON path/to/config.json;
};
```

* `contents.client-launcher`: a nix derivation of the client launcher
* `contents.server-laucnher`: a nix derivation of the server launcher
* `contents.mods`: a nix list containing all derivations of mods
* `contents.mods-combined`: a nix derivation of a folder containing all mods
* `contents.mods-zip`: a nix derivation of a zip file containing all mods

</details>

## About CurseForge

You need a CurseForge API key from <https://console.curseforge.com> to use CurseForge mods.

```shell
$ export CURSEFORGE_API_KEY="YOUR_API_KEY"
$ nix run "github:linyinfeng/mc-config#update"
...
```

## Flake template

[linyinfeng/mc-config-template](https://github.com/linyinfeng/mc-config-template) is a template repository with some convenient GitHub workflows for automated updating and releasing.
