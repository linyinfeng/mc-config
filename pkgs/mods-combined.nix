{ runCommand, lib, mods }:

let
  installCommand = mod: ''
    cp ${mod} "$out/${mod.name}"
  '';
in runCommand "mods-combined" { } ''
  mkdir $out
  ${lib.concatMapStringsSep "\n" installCommand mods}
''
