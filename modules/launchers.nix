{
  self,
  config,
  options,
  pkgs,
  lib,
  ...
}: let
  cfg = config.launchers;
in {
  options.launchers = {
    lockFile = lib.mkOption {
      type = lib.types.path;
      description = lib.mdDoc ''
        Locked configuration file, used by `mkLaunchers`.
      '';
    };
    lockedConfig = lib.mkOption {
      inherit (options.mcConfig) type;
      description = lib.mdDoc ''
        Locked configuration, used by `mkLaunchers`.
      '';
      default = builtins.fromJSON (builtins.readFile cfg.lockFile);
      defaultText = "fromJSON (readFile config.launchers.lockFile)";
    };
    mkLaunchers = lib.mkOption {
      type = lib.types.functionTo options.launchers.launchers.type;
      default = self.lib.mkLaunchers pkgs;
      defaultText = "mc-config.lib.mkLaunchers pkgs";
      description = lib.mdDoc ''
        `mkLaunchers` function to use.
      '';
    };
    build = lib.mkOption {
      type = with lib.types; attrsOf anything;
      description = lib.mdDoc ''
        Launcher packages.
      '';
      readOnly = true;
      default = cfg.mkLaunchers {launcherConfig = config.launchers.lockedConfig;};
      defaultText = "config.launchers.mkLaunchers { launcherConfig = config.launchers.lockedConfig; }";
    };
  };
}
