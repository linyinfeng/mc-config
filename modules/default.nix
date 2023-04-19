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
          "${inputs.nixpkgs}/nixos/modules/misc/nixpkgs.nix"
          {nixpkgs.hostPlatform = pkgs.stdenv.hostPlatform;}
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
