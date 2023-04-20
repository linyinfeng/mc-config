{
  lib,
  ...
}: {
  options.minecraft.build = lib.mkOption {
    type = with lib.types; attrsOf package;
    description = lib.mdDoc ''
      Attribute set of minecraft derivations.
    '';
  };
}
