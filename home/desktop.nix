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
    jamesdsp            # Audio effects processor

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

  # Autostart JamesDSP in tray
  xdg.configFile."autostart/jamesdsp.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=JamesDSP
    Exec=jamesdsp --tray
    Icon=jamesdsp
    Comment=Audio Effect Processor
    Terminal=false
    Categories=AudioVideo;Audio;
    StartupNotify=false
    X-GNOME-Autostart-enabled=true
  '';
}
