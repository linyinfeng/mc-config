{
  config,
  lib,
  ...
}: let
  itemOptions = {
    options = {
      name = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = ''
          Name of the item.
        '';
      };
      modrinthId = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = ''
          Modrinth Project ID of the item, can be found in "technical information" on webpage.
        '';
      };
      curseForgeId = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = ''
          CurseForge Project ID of the item, can be found in "About Project" on webpage.
        '';
      };
      url = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = ''
          Modrinth or CurseForge URL of the item.
        '';
      };
      filenameRegex = lib.mkOption {
        type = lib.types.str;
        default = ".*";
        example = ".*\.jar$";
        description = ''
          Regex to match filename. Some item contains multiple files,
          use this option for filtering or use the `primaryFileOnly` option.
        '';
      };
      fakeGameVersion = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        description = ''
          Check the item using this game version instead of `config.game.version`.
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
          Manually specify item version.
        '';
      };
      files = lib.mkOption {
        type = lib.types.listOf fileOptions;
        default = [];
        description = ''
          Manually specify item files.
        '';
      };
    };
  };
  itemSettingOptions = defaults: {
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
          Only use the primary file. Some item contains multiple files,
          use this option to select the primary file.
        '';
      };
    };
    config = lib.mkDefault defaults;
  };
  fileOptions = lib.types.submodule ../_common/file.nix;
  itemWithSettingOptions = kind:
    with lib.types;
      submoduleWith {
        modules = [
          itemOptions
          (itemSettingOptions config.minecraft."${kind}Defaults")
        ];
      };
  kinds = ["mod" "shaderPack" "resourcePack"];
  kindLoaders = {
    mod = ["fabric"];
    shaderPack = ["iris" "optifine"];
    resourcePack = [];
  };
  makeOptionsForKind = kind: [
    (lib.nameValuePair "${kind}Loader"
      (lib.mkOption {
        type = with lib.types; nullOr (enum (kindLoaders.${kind}));
        default =
          if lib.length kindLoaders.${kind} == 0
          then null
          else lib.elemAt kindLoaders.${kind} 0;
        description = lib.mkDoc ''
          Loader for ${kind}.
        '';
      }))
    (lib.nameValuePair "${kind}Defaults"
      (lib.mkOption {
        type = with lib.types; submodule (itemSettingOptions {});
        default = {};
        description = lib.mkDoc ''
          Default ${kind} settings.
        '';
      }))
    (lib.nameValuePair "${kind}s"
      (lib.mkOption {
        type = with lib.types; listOf (oneOf [(itemWithSettingOptions kind) str]);
        default = [];
        description = ''
          ${kind} definitions.
        '';
      }))
  ];
in {
  options.minecraft = lib.listToAttrs (lib.concatLists (lib.lists.map makeOptionsForKind kinds));
}
