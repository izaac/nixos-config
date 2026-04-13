{
  pkgs,
  lib,
  userConfig,
  ...
}: {
  # Stylix handles standard theming now.
  # Manual overrides go here.

  home = {
    # Set custom icon for Games folder
    activation.setGamesIcon = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD ${pkgs.glib}/bin/gio set -t string /home/${userConfig.username}/Games metadata::gvfs.extra-icon folder-cat-mocha-blue-games
    '';

    sessionVariables.GTK_THEME = "catppuccin-mocha-blue-standard";
  };

  gtk = {
    enable = true;
    gtk3.bookmarks = [
      "file:///home/${userConfig.username}/Documents Documents"
      "file:///home/${userConfig.username}/Downloads Downloads"
      "file:///home/${userConfig.username}/Music Music"
      "file:///home/${userConfig.username}/Pictures Pictures"
      "file:///home/${userConfig.username}/Videos Videos"
      "file:///home/${userConfig.username}/repos repos"
      "file:///home/${userConfig.username}/Games Games"
      "file:///mnt/storage storage"
      "file:///mnt/data data"
    ];
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  stylix.targets = {
    qt.enable = false; # Handled by kvantum manually
  };
}
