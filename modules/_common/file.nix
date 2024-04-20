{lib, ...}: {
  options = {
    filename = lib.mkOption {
      type = lib.types.str;
      description = ''
        Filename of the mod file.
      '';
    };
    file = {
      url = lib.mkOption {
        type = lib.types.str;
        description = ''
          URL to the file.
        '';
      };
      sha1 = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Sha1 hash of the file.
        '';
      };
      sha256 = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Sha1 hash of the file.
        '';
      };
      sha512 = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = ''
          Sha1 hash of the file.
        '';
      };
    };
  };
}
