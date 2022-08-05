{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";
    minecraft-nix.url = "github:ninlives/minecraft.nix";
    minecraft-nix.inputs.nixpkgs.follows = "nixpkgs";
    minecraft-nix.inputs.flake-utils.follows = "flake-utils-plus/flake-utils";
    minecraft-nix.inputs.metadata.follows = "minecraft-json";
    minecraft-json.url = "github:ninlives/minecraft.json";
    minecraft-json.inputs.nixpkgs.follows = "nixpkgs";
    minecraft-json.inputs.flake-utils.follows = "flake-utils-plus/flake-utils";
  };
  outputs = inputs@{ self, nixpkgs, flake-utils-plus, minecraft-nix, minecraft-json }:
    let utils = flake-utils-plus.lib;
    in utils.mkFlake {
      inherit self inputs;

      supportedSystems = [ "x86_64-linux" ];

      lib.mkLaunchers = pkgs: config:
        let system = pkgs.stdenv.hostPlatform.system;
        in pkgs.callPackage ./pkgs ({
          minecraft-nix-pkgs = minecraft-nix.legacyPackages.${system};
        } // config);

      outputsBuilder = channels:
        let
          pkgs = channels.nixpkgs;
          system = pkgs.stdenv.hostPlatform.system;
          inherit (pkgs) lib;
          contents = self.lib.mkLaunchers pkgs {
            launcherConfig = lib.importJSON ./config.json;
          };
        in
        {
          inherit contents;
          packages = utils.flattenTree contents // {
            update = pkgs.callPackage ./update { };
          };
          checks = self.packages.${system};
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [ fup-repl sops poetry black nixfmt fd ];
          };
        };
    };
}
