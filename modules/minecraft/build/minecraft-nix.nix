{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.minecraft-nix;
  inherit (pkgs.stdenv.hostPlatform) system;

  minecraftNixPkgs = inputs.minecraft-nix.legacyPackages.${system}."v${cfg.game.version}".${config.minecraft.modLoader};

  gameVersion = config.lock.content.game.version;
  lockMods = config.lock.content.mods;
  manualMods = lib.flatten (map (m:
    if lib.isAttrs m
    then m.files
    else [])
  config.minecraft.mods);
  modFiles = lockMods ++ manualMods;
  convertFile = f: pkgs.fetchurl ({name = f.filename;} // f.file);
  mods = map convertFile modFiles;
in {
  options = {
    minecraft-nix = {
      game.version = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        default = lib.replaceStrings ["." " "] ["_" "_"] gameVersion;
      };
      clientConfig = lib.mkOption {
        type = lib.types.anything;
      };
      serverConfig = lib.mkOption {
        type = lib.types.anything;
      };
    };
  };
  config = {
    minecraft-nix.clientConfig = {
      inherit (config.minecraft) files launchScript;
      inherit mods;
    };
    minecraft-nix.serverConfig = {
      inherit (config.minecraft) files launchScript;
      inherit mods;
    };
    minecraft.build = {
      client = minecraftNixPkgs.client.withConfig [cfg.clientConfig];
      server = minecraftNixPkgs.server.withConfig [cfg.serverConfig];
    };
  };
}
