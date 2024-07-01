{
  config,
  lib,
  ...
}: {
  options = {
    minecraft.game = {
      version = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = ''
          Minecraft game version.
        '';
      };
      versionRegex = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = ''
          Minecraft game version regex.
        '';
      };
    };
  };
  config = {
    assertions = [
      {
        assertion = config.minecraft.game.version != null || config.minecraft.game.versionRegex != null;
        message = ''
          Either `minecraft.game.version` or` minecraft.game.versionRegex` should be specified
        '';
      }
    ];
  };
}
