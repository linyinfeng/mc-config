{ lib, ... }:

{
  options = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "minecraft";
      description = lib.mdDoc ''
        Name of the configuration.
      '';
    };
  };
}
