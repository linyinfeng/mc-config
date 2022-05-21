{ stdenv, fetchurl, lib, serverConfig ? lib.importJSON ./config.json }:

stdenv.mkDerivation {
  pname = "minecraft-server";
  version = serverConfig.server.game.version;
  src = fetchurl serverConfig.server.game.server;
  dontUnpack = true;
  installPhase = ''
    cp $src $out
  '';
}
