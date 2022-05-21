{ stdenv, fetchurl, lib, serverConfig ? lib.importJSON ./config.json }:

let
  convertLibrary = lib:
    stdenv.mkDerivation {
      name = lib.name;
      src = fetchurl lib.file;
      dontUnpack = true;
      installPhase = ''
        cp $src $out
      '';
    };
in map convertLibrary serverConfig.server.fabricLoader.libraries
