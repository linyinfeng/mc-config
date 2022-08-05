{ stdenv, fetchurl, lib, launcherConfig }:

let
  convertFile = f:
    stdenv.mkDerivation {
      name = f.filename;
      src = fetchurl f.file;
      dontUnpack = true;
      installPhase = ''
        cp $src $out
      '';
    };
in
lib.flatten (map (cfg: map convertFile cfg.files) launcherConfig.mods)
