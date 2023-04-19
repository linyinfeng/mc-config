{ lib, minecraft-nix-pkgs, mods, launcherConfig }:

let
  gameVersion = lib.replaceStrings [ "." " " ] [ "_" "_" ]
    launcherConfig.game.version;
in
minecraft-nix-pkgs."v${gameVersion}".fabric.client.withConfig [{
  inherit mods;
}]
