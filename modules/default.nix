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
        ];
      specialArgs = {
        inherit inputs self;
      };
    }
    evalModulesArgs);
in
  evaled
  // {
    inherit pkgs;
  }
