{lib, ...}: {
  options = {
    minecraft.game.version = lib.mkOption {
      type = lib.types.str;
      description = lib.mdDoc ''
        Minecraft game version.
      '';
    };
  };
}
