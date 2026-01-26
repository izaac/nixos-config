{ pkgs, ... }:

{
  # --- FONTS ---
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    # Gnome Tools
    gnome-tweaks
    seahorse
    haruna
    pika-backup
    mission-center
    gnome-boxes
    virt-manager
    virt-viewer
    spice-gtk
    telegram-desktop

    # Audio Tools
    easyeffects
    amberol

    # General Software
    firefox
    celluloid
    foliate
    mpv
    ffmpeg-full
  ];

  # --- GNOME CONFIG ---
  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "dash-to-dock@micxgx.gmail.com"
        "clipboard-indicator@tudmotu.com"
        "caffeine@patapon.info"
        "blur-my-shell@aunetx"
        "vitals@corecoding.com"
        "AlphabeticalAppGrid@stuarthayhurst"
      ];
    };
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "BOTTOM";
      dock-fixed = false;
      dash-max-icon-size = 48;
      background-opacity = 0.8;
    };
    "org/gnome/shell/extensions/vitals" = {
      show-temperature = true;
      show-memory = true;
      show-cpu = true;
    };
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true; 
  };
}
