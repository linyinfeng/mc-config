{
  runCommand,
  lib,
  mods-combined,
  zip,
}:
runCommand "mods.zip" {} ''
  pushd ${mods-combined}
  ${zip}/bin/zip $out -r *
  popd
''
