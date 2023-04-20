{
  config,
  pkgs,
  lib,
  ...
}: let
  # client distribution
  inherit (config.minecraft-nix.clientConfig) mods;
in {
  minecraft.build = {
    mods-combined = let
      installCommand = mod: ''
        cp ${mod} "$out/${mod.name}"
      '';
    in
      pkgs.runCommand "mods-combined" {} ''
        mkdir $out
        ${lib.concatMapStringsSep "\n" installCommand mods}
      '';
    mods-zip = pkgs.runCommand "mods.zip" {} ''
      pushd ${config.minecraft.build.mods-combined}
      ${pkgs.zip}/bin/zip $out -r *
      popd
    '';
  };
}
