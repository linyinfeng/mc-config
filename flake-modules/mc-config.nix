{
  inputs,
  lib,
  flake-parts-lib,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (flake-parts-lib) mkTransposedPerSystemModule;
  mkPackage = name: key: value:
    if lib.isDerivation value
    then [(lib.nameValuePair "minecraft-${name}-${key}" value)]
    else [];
  mkPackages = name: mcCfg: lib.flatten (lib.mapAttrsToList (mkPackage name) mcCfg.config.launchers.build);
  mkChecks = mkPackages;
  mkAllWith = fn: mcCfgs: lib.listToAttrs (lib.flatten (lib.mapAttrsToList fn mcCfgs));
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
    perSystem = {self', ...}: {
      packages = mkAllWith mkPackages self'.minecraftConfigurations;
      checks = mkAllWith mkChecks self'.minecraftConfigurations;
    };
  };
}
