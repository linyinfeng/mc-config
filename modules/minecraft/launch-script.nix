# https://github.com/Ninlives/minecraft.nix/blob/main/module/common/launch-script.nix
{lib, ...}: let
  inherit (lib) mkOption mapAttrs optionalAttrs;
  inherit (lib.types) attrsOf listOf nullOr str lines submodule oneOf package bool enum;
  scriptOptions = {
    options = {
      type = mkOption {
        type = enum ["server" "client" "both"];
        default = "both";
      };
      deps = mkOption {
        type = listOf str;
        default = [];
        description = "List of script dependencies.";
      };
      text = mkOption {
        type = nullOr lines;
        default = null;
        description = "The content of the script.";
      };
    };
  };
in {
  options = {
    minecraft.launchScript = {
      preparation = mkOption {
        type = attrsOf (submodule scriptOptions);
        description = "Set of preparation scripts.";
        default = {};
        apply = scripts:
          mapAttrs (_name: s:
            # allow deps only script
              {inherit (s) type deps;}
              // (optionalAttrs (s.text != null)
                {inherit (s) text;}))
          scripts;
      };
      inheritPath = mkOption {
        type = bool;
        default = false;
        description = ''
          Whether to inherit the PATH environment variable from parent process.
        '';
      };
      path = mkOption {
        type = listOf (oneOf [package str]);
        default = [];
        description = ''
          Packages added to launch script's PATH environment variable.
          Only the bin directory will be added.
        '';
      };
    };
  };
}
