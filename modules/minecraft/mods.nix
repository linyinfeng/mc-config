{
  lib,
  options,
  ...
}: let
  modOptions = {
    options = {
      name = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = ''
          Name of the mod.
        '';
      };
      modrinthId = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = ''
          Modrinth Project ID of the mod, can be found in "technical information" on webpage.
        '';
      };
      curseForgeId = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = ''
          CurseForge Project ID of the mod, can be found in "About Project" on webpage.
        '';
      };
      url = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = ''
          Modrinth or CurseForge URL of the mod.
        '';
      };
      versionTypeRegex = lib.mkOption {
        type = lib.types.str;
        default = "release";
        example = "release|beta";
        description = ''
          Regex to match version type.
          Possible version types: "release", "beta", "alpha".
        '';
      };
      filenameRegex = lib.mkOption {
        type = lib.types.str;
        default = ".*";
        example = ".*\.jar$";
        description = ''
          Regex to match filename. Some mod contains multiple files,
          use this option for filtering or use the `primaryFileOnly` option.
        '';
      };
      primaryFileOnly = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Only use the primary file. Some mod contains multiple files,
          use this option to select the primary file.
        '';
      };
      fakeGameVersion = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = ''
          Check the mod using this game version instead of `config.game.version`.
        '';
      };
      manual = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Manually specify version and files.
        '';
      };
      version = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = ''
          Manually specify mod version.
        '';
      };
      files = lib.mkOption {
        type = lib.types.listOf fileOptions;
        default = [];
        description = ''
          Manually specify mod files.
        '';
      };
    };
  };
  fileOptions = lib.types.submodule ../_common/file.nix;
in {
  options = {
    minecraft = {
      modLoader = lib.mkOption {
        type = with lib.types; nullOr (enum ["fabric"]);
        default = "fabric";
        description = lib.mkDoc ''
          Mod loader to use.
        '';
      };
      mods = lib.mkOption {
        type = with lib.types; listOf (oneOf [(submodule modOptions) str]);
        description = ''
          Fabric mods definition.
        '';
      };
    };
  };
}
