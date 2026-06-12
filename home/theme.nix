{
  config,
  pkgs,
  lib,
  ...
}: {
  # Stylix handles standard theming now.
  # Manual overrides go here.

  config = lib.mkIf pkgs.stdenv.isLinux {
    home = {
      # Set custom icon for Games folder
      activation.setGamesIcon = lib.hm.dag.entryAfter ["writeBoundary"] ''
        $DRY_RUN_CMD ${pkgs.glib}/bin/gio set -t string ${config.home.homeDirectory}/Games metadata::gvfs.extra-icon folder-cat-mocha-blue-games || true
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
        "file://${config.home.homeDirectory}/Documents Documents"
        "file://${config.home.homeDirectory}/Downloads Downloads"
        "file://${config.home.homeDirectory}/Music Music"
        "file://${config.home.homeDirectory}/Pictures Pictures"
        "file://${config.home.homeDirectory}/Videos Videos"
        "file://${config.home.homeDirectory}/repos repos"
        "file://${config.home.homeDirectory}/Games Games"
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
