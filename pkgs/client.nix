{
  lib,
  mods,
  minecraftNix,
  config,
}: let
  gameVersion = lib.replaceStrings ["." " "] ["_" "_"] config.minecraft.game.version;
in
  minecraftNix."v${gameVersion}".fabric.client.withConfig [
    {
      inherit mods;
    }
  ]
