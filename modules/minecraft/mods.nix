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
        description = lib.mdDoc ''
          Name of the mod.
        '';
      };
      modrinthId = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = lib.mdDoc ''
          Modrinth Project ID of the mod, can be found in "technical information" on webpage.
        '';
      };
      curseForgeId = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = lib.mdDoc ''
          CurseForge Project ID of the mod, can be found in "About Project" on webpage.
        '';
      };
      url = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = lib.mdDoc ''
          Modrinth or CurseForge URL of the mod.
        '';
      };
      versionTypeRegex = lib.mkOption {
        type = lib.types.str;
        default = "release";
        example = "release|beta";
        description = lib.mdDoc ''
          Regex to match version type.
          Possible version types: "release", "beta", "alpha".
        '';
      };
      filenameRegex = lib.mkOption {
        type = lib.types.str;
        default = ".*";
        example = ".*\.jar$";
        description = lib.mdDoc ''
          Regex to match filename. Some mod contains multiple files,
          use this option for filtering or use the `primaryFileOnly` option.
        '';
      };
      primaryFileOnly = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = lib.mdDoc ''
          Only use the primary file. Some mod contains multiple files,
          use this option to select the primary file.
        '';
      };
      fakeGameVersion = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = lib.mdDoc ''
          Check the mod using this game version instead of `config.game.version`.
        '';
      };
      manual = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = lib.mdDoc ''
          Manually specify version and files.
        '';
      };
      version = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = lib.mdDoc ''
          Manually specify mod version.
        '';
      };
      files = lib.mkOption {
        type = lib.types.listOf fileOptions;
        default = [];
        description = lib.mdDoc ''
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
        description = lib.mdDoc ''
          Fabric mods definition.
        '';
      };
    };
  };
}
