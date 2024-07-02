{...}: {
  minecraft.files."allowed_symlinks.txt".text = ''
    [prefix]/nix/store/
  '';
}
