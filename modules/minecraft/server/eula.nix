{
  config,
  lib,
  ...
}: let
  cfg = config.minecraft.server.eula;
in {
  options = {
    minecraft.server.eula = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether you agree to Mojangs EULA.
      '';
    };
  };
  config = lib.mkIf cfg {
    minecraft = {
      files."eula.txt".text = ''
        eula=true
      '';
      launchScript.preparation = {
        linkFiles.deps = ["removeOldEulaFile"];
        removeOldEulaFile = {
          deps = ["enterWorkingDirectory"];
          text = ''
            rm -f eula.txt
          '';
        };
      };
    };
  };
}
