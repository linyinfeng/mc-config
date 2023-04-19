{
  fetchurl,
  lib,
  config,
}: let
  lockMods = config.lock.content.mods;
  manualMods = lib.flatten (map (m:
    if lib.isAttrs m
    then m.files
    else [])
  config.minecraft.mods);
  mods = lockMods ++ manualMods;
  convertFile = f: fetchurl ({name = f.filename;} // f.file);
in
  map convertFile mods
