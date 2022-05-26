{ lib, minecraft-nix-pkgs, mods, serverConfig }:

let
  gameVersion =
    lib.replaceStrings [ "." " " ] [ "_" "_" ] serverConfig.server.game.version;
in minecraft-nix-pkgs."v${gameVersion}".fabric.server.withConfig [{
  inherit mods;
}]
