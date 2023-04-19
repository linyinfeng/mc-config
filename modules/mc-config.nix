{
  config,
  lib,
  ...
}: let
  mcConfigOptions = {
    options = {
      game.version = lib.mkOption {
        type = lib.types.str;
        description = lib.mdDoc ''
          Minecraft game version.
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
        type = with lib.types; listOf (submodule fileOptions);
        default = [];
        description = lib.mdDoc ''
          Manually specify mod files.
        '';
      };
    };
  };
  fileOptions = {
    options = {
      filename = lib.mkOption {
        type = lib.types.str;
        description = lib.mdDoc ''
          Filename of the mod file.
        '';
      };
      file = {
        url = lib.mkOption {
          type = lib.types.str;
          description = lib.mdDoc ''
            URL to the file.
          '';
        };
        sha1 = lib.mkOption {
          type = with lib.types; nullOr str;
          description = lib.mdDoc ''
            Sha1 hash of the file.
          '';
        };
        sha256 = lib.mkOption {
          type = with lib.types; nullOr str;
          description = lib.mdDoc ''
            Sha1 hash of the file.
          '';
        };
        sha512 = lib.mkOption {
          type = with lib.types; nullOr str;
          description = lib.mdDoc ''
            Sha1 hash of the file.
          '';
        };
      };
    };
  };
in {
  options = {
    mcConfig = lib.mkOption {
      type = lib.types.submodule mcConfigOptions;
      description = lib.mdDoc ''
        Minecraft configurations.
      '';
    };
  };
}
