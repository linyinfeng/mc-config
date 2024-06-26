{
  lib,
  flake-parts-lib,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (flake-parts-lib) mkTransposedPerSystemModule;
  mkPackage = name: key: value: lib.nameValuePair "minecraft-${name}-${key}" value;
  mkPackages = name: mcCfg:
    lib.mapAttrsToList (mkPackage name) mcCfg.config.minecraft.build
    ++ [
      (lib.nameValuePair "minecraft-${name}-update" mcCfg.config.update.script)
    ];
  mkApps = name: mcCfg: [
    (lib.nameValuePair "minecraft-${name}-update" {
      type = "app";
      program = lib.getExe mcCfg.config.update.script;
    })
    (lib.nameValuePair "minecraft-${name}-client" {
      type = "app";
      program = lib.getExe mcCfg.config.minecraft.build.client;
    })
    (lib.nameValuePair "minecraft-${name}-server" {
      type = "app";
      program = lib.getExe mcCfg.config.minecraft.build.server;
    })
  ];
  mkChecks = mkPackages;
  mkAllWith = fn: mcCfgs: lib.listToAttrs (lib.concatLists (lib.mapAttrsToList fn mcCfgs));
in {
  imports = [
    (mkTransposedPerSystemModule {
      name = "minecraftConfigurations";
      file = ./mc-config.nix;
      option = mkOption {
        type = types.lazyAttrsOf types.raw;
        default = {};
        description = ''
          Attrset of minecraft configurations.
        '';
      };
    })
  ];

  config = {
    perSystem = {
      options,
      config,
      self',
      ...
    }: {
      config =
        {
          packages = mkAllWith mkPackages config.minecraftConfigurations;
          apps = mkAllWith mkApps self'.minecraftConfigurations;
          checks = mkAllWith mkChecks self'.minecraftConfigurations;
        }
        // (
          if options ? overlayAttrs
          then {overlayAttrs = config.packages;}
          else {}
        );
    };
  };
}
