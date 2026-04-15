{lib, ...}: {
  qt = {
    enable = true;
    platformTheme.name = lib.mkForce "kvantum";
    style.name = lib.mkForce "kvantum";
  };

  # dconf color-scheme handled in theme.nix
}
