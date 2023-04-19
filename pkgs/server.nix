{
  lib,
  minecraftNix,
  mods,
  config,
}: let
  gameVersion =
    lib.replaceStrings ["." " "] ["_" "_"]
    config.minecraft.game.version;
in
  minecraftNix."v${gameVersion}".fabric.server.withConfig [
    {
      inherit mods;
    }
  ]
