{
  pkgs,
  lib,
  userConfig,
  ...
}: {
  # Stylix handles standard theming now.
  # Manual overrides go here.

  config = lib.mkIf pkgs.stdenv.isLinux {
    home = {
      # Set custom icon for Games folder
      activation.setGamesIcon = lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD ${pkgs.glib}/bin/gio set -t string /home/${userConfig.username}/Games metadata::gvfs.extra-icon folder-cat-mocha-blue-games || true
      '';
    };

    gtk = {
      enable = true;
      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };
      gtk4 = {
        extraConfig.gtk-application-prefer-dark-theme = 1;
      };
      gtk3.extraConfig.gtk-application-prefer-dark-theme = 1;
      gtk3.bookmarks = [
        "file:///home/${userConfig.username}/Documents Documents"
        "file:///home/${userConfig.username}/Downloads Downloads"
        "file:///home/${userConfig.username}/Music Music"
        "file:///home/${userConfig.username}/Pictures Pictures"
        "file:///home/${userConfig.username}/Videos Videos"
        "file:///home/${userConfig.username}/repos repos"
        "file:///home/${userConfig.username}/Games Games"
        "file:///mnt/data data"
      ];
    };

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };

    stylix = {
      targets = {
        qt.enable = false; # Handled by kvantum manually
      };
    };
  };
}
