{ pkgs, ... }:

{
  # --- FONTS ---
  fonts.fontconfig.enable = true;
  
  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    
    # --- GNOME EXTENSIONS
    gnomeExtensions.appindicator        # Tray Icons support

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
    lsp-plugins         # Pro-grade audio plugins
    calf                # Common audio effects

    # General Software
    filezilla       # WinSCP Replacement
    sushi           # "Spacebar" file previewer
    celluloid
    foliate
    mpv
    ffmpeg-full
    jellyfin-desktop
  ];

  # --- GNOME CONFIG ---
  # Enable installed Gnome extensions
  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
      ];
    };
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true; 
  };
}
