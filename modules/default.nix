{
  inputs,
  self,
  modules,
  pkgs,
  lib ? pkgs.lib,
  evalModulesArgs ? {},
}: let
  mmModules = import ./module-list.nix;
  evaled = lib.evalModules (lib.recursiveUpdate
    {
      modules =
        modules
        ++ mmModules
        ++ [
          {_module.args = {inherit pkgs;};}
          "${pkgs.path}/nixos/modules/misc/assertions.nix"
        ];
      specialArgs = {
        inherit inputs self;
      };
    }
    evalModulesArgs);

  result =
    evaled
    // {
      inherit pkgs;
    };

  failedAssertions = map (x: x.message) (lib.filter (x: !x.assertion) evaled.config.assertions);
  resultAssertWarn =
    if failedAssertions != []
    then throw "\nFailed assertions:\n${lib.concatStringsSep "\n" (map (x: "- ${x}") failedAssertions)}"
    else lib.showWarnings evaled.config.warnings result;
in
  resultAssertWarn
