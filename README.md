# mc-config

A simple Minecraft mod manager in nix (*fabric only*), based on [minecraft.nix](https://github.com/ninlives/minecraft.nix).

## Usage

Please refer to the template repository [mc-config-template](https://github.com/linyinfeng/mc-config-template), and read `flake.nix` and `minecraft.nix`.

## About CurseForge

You need a CurseForge API key from <https://console.curseforge.com> to use CurseForge mods.

```shell
$ export CURSEFORGE_API_KEY="YOUR_API_KEY"
$ nix run "github:linyinfeng/mc-config#update"
...
```

## Flake template

[linyinfeng/mc-config-template](https://github.com/linyinfeng/mc-config-template) is a template repository with some convenient GitHub workflows for automated updating and releasing.
