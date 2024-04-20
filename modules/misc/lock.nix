{
  config,
  lib,
  ...
}: let
  cfg = config.lock;
  lockContentOptions = {
    options = {
      mods = lib.mkOption {
        type = lib.types.listOf fileOptions;
      };
    };
  };
  fileOptions = lib.types.submodule ../_common/file.nix;
in {
  options = {
    lock = {
      file = lib.mkOption {
        type = lib.types.path;
        description = ''
          Genearted lockFile, used by `mkMinecraftPkgs`.
        '';
      };
      content = lib.mkOption {
        type = lib.types.submodule lockContentOptions;
        description = ''
          Content of lock file.
        '';
        default = builtins.fromJSON (builtins.readFile cfg.file);
        defaultText = "fromJSON (readFile cfg.file)";
      };
    };
  };
}
