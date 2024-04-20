{lib, ...}: {
  options = {
    minecraft.game.version = lib.mkOption {
      type = lib.types.str;
      description = ''
        Minecraft game version.
      '';
    };
  };
}
