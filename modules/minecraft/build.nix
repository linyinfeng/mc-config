{lib, ...}: {
  options.minecraft.build = lib.mkOption {
    type = with lib.types;
      submoduleWith {
        modules = [
          {
            freeformType = lazyAttrsOf (uniq unspecified);
          }
        ];
      };
    description = ''
      Attribute set of minecraft derivations.
    '';
  };
}
