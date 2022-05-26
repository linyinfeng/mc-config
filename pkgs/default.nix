{ pkgs, lib, serverConfig, minecraft-nix-pkgs }:

let inherit (pkgs) lib newScope;

in lib.makeScope newScope (self:
  let inherit (self) callPackage;
  in {
    inherit serverConfig;
    server-launcher =
      callPackage ./server-launcher.nix { inherit minecraft-nix-pkgs; };
    client-launcher =
      callPackage ./client-launcher.nix { inherit minecraft-nix-pkgs; };
    mods = callPackage ./mods.nix { };
    mods-combined = callPackage ./mods-combined.nix { };
    mods-zip = callPackage ./mods-zip.nix { };
  })
