{ lib, minecraft-nix-pkgs, mods, launcherConfig }:

let
  gameVersion = lib.replaceStrings [ "." " " ] [ "_" "_" ]
    launcherConfig.server.game.version;
in minecraft-nix-pkgs."v${gameVersion}".fabric.server.withConfig [{
  inherit mods;
}]
