{
  pkgs,
  lib,
  userConfig,
  ...
}: let
  catppuccin-papirus = pkgs.catppuccin-papirus-folders.override {
    flavor = "mocha";
    accent = "blue";
  };
  catppuccin-gtk-overridden = pkgs.catppuccin-gtk.override {
    accents = ["blue"];
    size = "standard";
    tweaks = ["rimless"];
    variant = "mocha";
  };
in {
  catppuccin.enable = true;
  catppuccin.vscode.profiles.default.enable = false;
  catppuccin.flavor = "mocha";
  catppuccin.accent = "blue";

  # Use Bibata Modern Ice for a blue pointer matching COSMIC aesthetic
  home.pointerCursor = {
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
    x11.enable = true;
  };

  # Enable specific integrations (but disable Catppuccin cursors to use Bibata)
  catppuccin.cursors.enable = false;
  # LazyVim manages catppuccin-nvim itself; disable HM module injection
  catppuccin.nvim.enable = false;

  home.packages = with pkgs; [
    catppuccin-papirus
  ];

  gtk = {
    enable = true;
    gtk4.theme = null;
    theme = {
      name = "catppuccin-mocha-blue-standard";
      package = catppuccin-gtk-overridden;
    };
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

  # Theme Libadwaita
  home.sessionVariables.GTK_THEME = "catppuccin-mocha-blue-standard";

  # GTK 4 settings
  xdg.configFile."gtk-4.0/gtk.css".source = "${catppuccin-gtk-overridden}/share/themes/catppuccin-mocha-blue-standard/gtk-4.0/gtk.css";
  xdg.configFile."gtk-4.0/gtk-dark.css".source = "${catppuccin-gtk-overridden}/share/themes/catppuccin-mocha-blue-standard/gtk-4.0/gtk-dark.css";
  xdg.configFile."gtk-4.0/assets".source = "${catppuccin-gtk-overridden}/share/themes/catppuccin-mocha-blue-standard/gtk-4.0/assets";

  # Set custom icon for Games folder
  home.activation.setGamesIcon = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${pkgs.glib}/bin/gio set -t string /home/${userConfig.username}/Games metadata::gvfs.extra-icon folder-cat-mocha-blue-games
  '';

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
