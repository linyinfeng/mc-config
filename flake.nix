{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";
    systems.url = "github:nix-systems/default";
    minecraft-nix.url = "github:ninlives/minecraft.nix";
    minecraft-nix.inputs.nixpkgs.follows = "nixpkgs";
    minecraft-nix.inputs.flake-utils.follows = "flake-utils";
    minecraft-nix.inputs.metadata.follows = "minecraft-json";
    minecraft-json.url = "github:ninlives/minecraft.json";
    minecraft-json.inputs.nixpkgs.follows = "nixpkgs";
    minecraft-json.inputs.flake-utils.follows = "flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} ({
      self,
      inputs,
      ...
    }: {
      systems = import inputs.systems;
      imports = [
        inputs.treefmt-nix.flakeModule
      ];
      flake = {
        flakeModules = import ./flake-modules;
        lib = {
          minecraftConfiguration = args: import ./modules (args // {inherit self inputs;});
          mkMinecraftPkgs = pkgs: config: let
            system = pkgs.stdenv.hostPlatform.system;
          in
            pkgs.callPackage ./pkgs ({
                minecraftNix = inputs.minecraft-nix.legacyPackages.${system};
              }
              // config);
          mkLaunchers = throw "`mkLaunchers` has been replaced by `mkMinecraftPkgs`";
        };
      };
      perSystem = {
        self',
        pkgs,
        ...
      }: {
        packages.update = pkgs.callPackage ./update {};
        checks = self'.packages;
        treefmt = {
          projectRootFile = "flake.nix";
          programs = {
            alejandra.enable = true;
            black.enable = true;
          };
        };
      };
    });
}
