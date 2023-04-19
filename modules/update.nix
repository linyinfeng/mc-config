{
  self,
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.update;
  inherit (pkgs.stdenv.hostPlatform) system;
in {
  options = {
    update = {
      package = lib.mkOption {
        type = lib.types.package;
        description = lib.mdDoc ''
          Update package to use.
        '';
        default = self.packages.${system}.update;
        defaultText = "mc-config.packages.\${system}.update";
      };
      script = lib.mkOption {
        type = lib.types.package;
        description = lib.mdDoc ''
          Update script to create lock file.
        '';
        defaultText = "\${config.update.package}/bin/update --config-input MC_CONFIG --config-output \${config.update.lockFileName}";
        default = let
          configFile = pkgs.writeText "mc-config-${config.name}" (builtins.toJSON config.mcConfig);
        in
          pkgs.writeShellScriptBin "mc-config-update-${config.name}" ''
            "${cfg.package}/bin/update" \
              --config-input ${configFile} \
              --config-output ${cfg.lockFileName} \
              "$@"
          '';
      };
      lockFileName = lib.mkOption {
        type = lib.types.str;
        description = lib.mdDoc ''
          Name of the lock file, used by the update script.
        '';
        default = "${config.name}.lock";
        defaultText = "\${config.name}.lock";
      };
    };
  };
}
