{ writeShellScriptBin, lib, serverConfig, minecraft-server, mods
, fabric-libraries, jre }:

assert fabric-libraries != [ ];

writeShellScriptBin "server" ''
  set -e

  ${jre}/bin/java \
    --class-path='${minecraft-server}:${
      lib.concatStringsSep ":" fabric-libraries
    }' \
    ${
      lib.optionalString (mods != [ ])
      "-Dfabric.addMods='${lib.concatStringsSep ":" mods}'"
    } \
    ${serverConfig.server.fabricLoader.mainClass} \
    "$@"
''
