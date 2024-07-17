# https://github.com/Ninlives/minecraft.nix/blob/main/module/common/files.nix
{
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkOption mkIf mapAttrs;
  inherit (lib.types) attrsOf bool nullOr path str submodule enum;
  inherit (pkgs) writeText;
  fileOptions = {
    config,
    name,
    ...
  }: {
    options = {
      type = mkOption {
        type = enum ["server" "client" "both"];
        default = "both";
      };
      name = mkOption {
        type = str;
        default = name;
        defaultText = "<name>";
      };
      enable = mkOption {
        type = bool;
        default = true;
        description = ''
          Wheater to link this file or directory.
        '';
      };
      text = mkOption {
        type = nullOr str;
        default = null;
        description = ''
          Text of the file. If this option is null then `file.<name>.source`
          must be set.
        '';
      };
      source = mkOption {
        type = path;
        description = ''
          Path to the source file or directory.
        '';
      };
      target = mkOption {
        type = str;
        default = name;
        defaultText = "<name>";
        description = ''
          Path to target file or directory.
        '';
      };
      recursive = mkOption {
        type = bool;
        default = false;
        description = ''
          Whether to link contents of the directory recursively instead of linking the whole directory.
        '';
      };
    };
    config = {
      source = mkIf (config.text != null) (writeText name config.text);
    };
  };
in {
  options = {
    minecraft.files = mkOption {
      type = attrsOf (submodule fileOptions);
      description = "Set files to link into the working directory of minecraft.";
      default = {};
      apply = fs: mapAttrs (_name: f: f // {text = null;}) fs;
    };
  };
}
