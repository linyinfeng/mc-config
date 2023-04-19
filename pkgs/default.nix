{
  newScope,
  lib,
  minecraftNix,
  config,
}:
lib.makeScope newScope (self: let
  inherit (self) callPackage;
in {
  inherit config;
  inherit minecraftNix;
  server = callPackage ./server.nix {};
  client = callPackage ./client.nix {};
  mods = callPackage ./mods.nix {};
  mods-combined = callPackage ./mods-combined.nix {};
  mods-zip = callPackage ./mods-zip.nix {};
})
