{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils-plus.url = "github:gytis-ivaskevicius/flake-utils-plus";
    minecraft-nix.url = "github:ninlives/minecraft.nix";
    minecraft-nix.inputs.nixpkgs.follows = "nixpkgs";
    minecraft-nix.inputs.flake-utils.follows = "flake-utils-plus/flake-utils";
  };
  outputs = inputs@{ self, nixpkgs, flake-utils-plus, minecraft-nix }:
    let utils = flake-utils-plus.lib;
    in utils.mkFlake {
      inherit self inputs;

      outputsBuilder = channels:
        let
          pkgs = channels.nixpkgs;
          system = pkgs.stdenv.hostPlatform.system;
          inherit (pkgs) lib;
          serverConfig = lib.importJSON ./config.json;
          contents = pkgs.callPackage ./pkgs {
            inherit serverConfig;
            minecraft-nix-pkgs = minecraft-nix.legacyPackages.${system};
          };
        in {
          inherit contents;
          packages = utils.flattenTree contents // {
            update = pkgs.callPackage ./update { };
          };
          devShell = pkgs.mkShell {
            packages = with pkgs; [ fup-repl sops poetry black nixfmt ];
          };
        };
    };
}
