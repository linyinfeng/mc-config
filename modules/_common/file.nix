{lib, ...}: {
  options = {
    filename = lib.mkOption {
      type = lib.types.str;
      description = lib.mdDoc ''
        Filename of the mod file.
      '';
    };
    file = {
      url = lib.mkOption {
        type = lib.types.str;
        description = lib.mdDoc ''
          URL to the file.
        '';
      };
      sha1 = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = lib.mdDoc ''
          Sha1 hash of the file.
        '';
      };
      sha256 = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = lib.mdDoc ''
          Sha1 hash of the file.
        '';
      };
      sha512 = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = lib.mdDoc ''
          Sha1 hash of the file.
        '';
      };
    };
  };
}
