{lib, ...}: {
  options.minecraft.build = lib.mkOption {
    type = with lib.types; attrsOf package;
    description = ''
      Attribute set of minecraft derivations.
    '';
  };
}
