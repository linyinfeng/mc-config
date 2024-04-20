{lib, ...}: {
  options = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "minecraft";
      description = ''
        Name of the configuration.
      '';
    };
  };
}
