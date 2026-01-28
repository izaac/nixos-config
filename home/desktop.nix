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

  # Default Applications (File Associations)
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox.desktop" ];
      
      # Text
      "text/plain" = [ "org.gnome.TextEditor.desktop" ];
      "text/markdown" = [ "org.gnome.TextEditor.desktop" ];
      "text/x-log" = [ "org.gnome.TextEditor.desktop" ];

      # Archives
      "application/zip" = [ "peazip.desktop" ];
      "application/x-tar" = [ "peazip.desktop" ];
      "application/x-7z-compressed" = [ "peazip.desktop" ];
      "application/x-rar" = [ "peazip.desktop" ];
      "application/gzip" = [ "peazip.desktop" ];
      "application/x-bzip2" = [ "peazip.desktop" ];
      "application/x-xz" = [ "peazip.desktop" ];
      
      # Video
      "video/mp4" = [ "haruna.desktop" ];
      "video/x-matroska" = [ "haruna.desktop" ];
      "video/webm" = [ "haruna.desktop" ];
      "video/quicktime" = [ "haruna.desktop" ];
      
      # Audio
      "audio/mpeg" = [ "amberol.desktop" ];
      "audio/flac" = [ "amberol.desktop" ];
      "audio/x-wav" = [ "amberol.desktop" ];
      
      # Documents / Images
      "application/pdf" = [ "firefox.desktop" ];
      "application/epub+zip" = [ "com.github.johnfactotum.Foliate.desktop" ];
      "image/png" = [ "org.gnome.Loupe.desktop" ];
      "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
      "image/webp" = [ "org.gnome.Loupe.desktop" ];
      "image/gif" = [ "org.gnome.Loupe.desktop" ];
      "image/svg+xml" = [ "org.gnome.Loupe.desktop" ];
      "image/bmp" = [ "org.gnome.Loupe.desktop" ];
      "image/tiff" = [ "org.gnome.Loupe.desktop" ];
      
      # Directories
      "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
    };
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
