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
        description = ''
          Update package to use.
        '';
        default = self.packages.${system}.update;
        defaultText = "mc-config.packages.\${system}.update";
      };
      script = lib.mkOption {
        type = lib.types.package;
        description = ''
          Update script to create lock file.
        '';
        defaultText = "\${config.update.package}/bin/update --config CONFIG_FILE --lock-file \${config.update.lockFile}";
        default = let
          configContent = {
            inherit (config.minecraft) game mods modDefaults;
          };
          configFile =
            pkgs.writeText "mc-config-${config.name}.json"
            (builtins.toJSON configContent);
        in
          pkgs.writeShellScriptBin "mc-config-update-${config.name}" ''
            "${cfg.package}/bin/update" \
              --config ${configFile} \
              --lock-file ${cfg.lockFile} \
              "$@"
          '';
      };
      lockFile = lib.mkOption {
        type = lib.types.str;
        description = ''
          Output path of the lock file, used by the update script.
        '';
        default = "${config.name}.lock";
        defaultText = "\${config.name}.lock";
      };
    };
  };
}
