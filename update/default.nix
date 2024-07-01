{
  minecraft-json,
  writeShellScriptBin,
  python3,
}: let
  pyEnv = python3.withPackages (p: with p; [iso8601 requests natsort]);
in
  writeShellScriptBin "update" ''
    ${pyEnv}/bin/python ${./update.py} --game-manifests "${minecraft-json}/vanilla/manifests.json" "$@"
  ''
