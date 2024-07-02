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
  makeItemFiles = kind: let
    lockedItems = config.lock.content."${kind}s";
    manualItems = lib.flatten (map (m:
      if lib.isAttrs m
      then m.files
      else [])
    config.minecraft."${kind}s");
    itemFiles = lockedItems ++ manualItems;
    convertFile = f: pkgs.fetchurl ({name = f.filename;} // f.file);
    files = map convertFile itemFiles;
  in
    files;
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
      mods = makeItemFiles "mod";
      shaderPacks = makeItemFiles "shaderPack";
      resourcePacks = makeItemFiles "resourcePack";
    };
    minecraft-nix.serverConfig = {
      inherit (config.minecraft) files launchScript;
      mods = makeItemFiles "mod";
    };
    minecraft.build = {
      client = minecraftNixPkgs.client.withConfig [cfg.clientConfig];
      server = minecraftNixPkgs.server.withConfig [cfg.serverConfig];
    };
  };
}
