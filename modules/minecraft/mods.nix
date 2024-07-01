{
  config,
  lib,
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
      filenameRegex = lib.mkOption {
        type = lib.types.str;
        default = ".*";
        example = ".*\.jar$";
        description = ''
          Regex to match filename. Some mod contains multiple files,
          use this option for filtering or use the `primaryFileOnly` option.
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
  modSettingOptions = defaults: {
    options = {
      versionTypeRegex = lib.mkOption {
        type = lib.types.str;
        default = "release";
        example = "release|beta";
        description = ''
          Regex to match version type.
          Possible version types: "release", "beta", "alpha".
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
    };
    config = lib.mkDefault defaults;
  };
  fileOptions = lib.types.submodule ../_common/file.nix;
  modWithSettingOptions = with lib.types;
    submoduleWith {
      modules = [
        modOptions
        (modSettingOptions config.minecraft.modDefaults)
      ];
    };
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
      modDefaults = lib.mkOption {
        type = with lib.types; submodule (modSettingOptions {});
        default = {};
        description = lib.mkDoc ''
          Default Fabric mods definition settings.
        '';
      };
      mods = lib.mkOption {
        type = with lib.types; listOf (oneOf [modWithSettingOptions str]);
        description = ''
          Fabric mods definition.
        '';
      };
    };
  };
}
