{ pkgs, ... }:

{
  # --- FONTS ---
  fonts.fontconfig.enable = true;
  
  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    
    # --- GNOME EXTENSIONS
    gnomeExtensions.appindicator        # The "Tray Icons" you asked for
    gnomeExtensions.dash-to-dock        # A better dock/taskbar
    gnomeExtensions.clipboard-indicator # Clipboard history
    gnomeExtensions.caffeine            # "Keep Awake" button
    gnomeExtensions.blur-my-shell       # Makes UI look modern/frosted
    gnomeExtensions.vitals              # CPU/Ram/Temp monitor in top bar
    gnomeExtensions.alphabetical-app-grid

    # Gnome Tools
    gnome-tweaks
    seahorse
    amberol
    haruna
    pika-backup
    mission-center
    gnome-boxes
    virt-manager
    virt-viewer
    spice-gtk
    telegram-desktop
    google-chrome
    boxbuddy

    # Audio Tools
    easyeffects

    # General Software
    firefox
    celluloid
    foliate
    mpv
    ffmpeg-full
    cava
    jellyfin-desktop
  ];

  # --- GNOME CONFIG ---
  # These UUIDs tell Gnome to turn on the packages we just added above.
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
