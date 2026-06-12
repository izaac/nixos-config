_: {
  # Stylix's qt target is disabled (home/theme.nix), so plain values
  # suffice — nothing to fight with mkForce.
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };

  # dconf color-scheme handled in theme.nix
}
