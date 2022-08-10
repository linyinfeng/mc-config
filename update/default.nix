{ writeShellScriptBin, python3 }:

let
  pyEnv = python3.withPackages (p: with p; [
    iso8601
    requests
  ]);
in
writeShellScriptBin "update" ''
  ${pyEnv}/bin/python ${./update.py} "$@"
''
