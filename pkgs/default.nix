{ pkgs, lib, serverConfig, minecraft-nix-pkgs }:

let inherit (pkgs) lib newScope;

in lib.makeScope newScope (self:
  let inherit (self) callPackage;
  in {
    inherit serverConfig;
    server-launcher = callPackage ./server-launcher.nix { };
    client-launcher =
      callPackage ./client-launcher.nix { inherit minecraft-nix-pkgs; };
    minecraft-server = callPackage ./minecraft-server.nix { };
    fabric-libraries = callPackage ./fabric-libraries.nix { };
    mods = callPackage ./mods.nix { };
    mods-combined = callPackage ./mods-combined.nix { };
  })
