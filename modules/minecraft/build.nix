{
  self,
  config,
  options,
  pkgs,
  lib,
  ...
}: {
  options.minecraft = {
    builders = {
      mkMinecraftPkgs = lib.mkOption {
        type = lib.types.functionTo options.minecraft.build.type;
        default = self.lib.mkMinecraftPkgs pkgs;
        defaultText = "mc-config.lib.mkMinecraftPkgs pkgs";
        description = lib.mdDoc ''
          `mkMinecraftPkgs` function to use.
        '';
      };
    };
    build = lib.mkOption {
      type = with lib.types; attrsOf anything;
      description = lib.mdDoc ''
        Launcher packages.
      '';
      readOnly = true;
      default = config.minecraft.builders.mkMinecraftPkgs {inherit config;};
      defaultText = "config.minecraft.builders.mkMinecraftPkgs {inherit config;}";
    };
  };
}
