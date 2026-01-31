{ pkgs, ... }:

{
  # --- FONTS ---
  fonts.fontconfig.enable = true;
  
  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    font-awesome
    
    # Essential Tools
    haruna          # Video Player (Qt/KDE friendly)
    telegram-desktop

    # Audio Tools
    lsp-plugins         # Pro-grade audio plugins
    calf                # Common audio effects
    jamesdsp            # Audio effects processor

    # General Software
    sparrow
    filezilla       # WinSCP Replacement
    mpv
    ffmpeg-full
    jellyfin-desktop
    
    # Virtualization (keep these)
    gnome-boxes
    virt-manager
    virt-viewer
    spice-gtk
    boxbuddy
  ];

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
      "text/plain" = [ "org.kde.kate.desktop" ];
      "text/markdown" = [ "org.kde.kate.desktop" ];
      "text/x-log" = [ "org.kde.kate.desktop" ];

      # Archives
      "application/zip" = [ "org.kde.ark.desktop" ];
      "application/x-tar" = [ "org.kde.ark.desktop" ];
      "application/x-7z-compressed" = [ "org.kde.ark.desktop" ];
      "application/x-rar" = [ "org.kde.ark.desktop" ];
      "application/gzip" = [ "org.kde.ark.desktop" ];
      "application/x-bzip2" = [ "org.kde.ark.desktop" ];
      "application/x-xz" = [ "org.kde.ark.desktop" ];
      
      # Video
      "video/mp4" = [ "haruna.desktop" ];
      "video/x-matroska" = [ "haruna.desktop" ];
      "video/webm" = [ "haruna.desktop" ];
      "video/quicktime" = [ "haruna.desktop" ];
      
      # Audio
      "audio/mpeg" = [ "org.kde.elisa.desktop" ];
      "audio/flac" = [ "org.kde.elisa.desktop" ];
      "audio/x-wav" = [ "org.kde.elisa.desktop" ];
      
      # Documents / Images
      "application/pdf" = [ "org.kde.okular.desktop" ];
      "application/epub+zip" = [ "org.kde.okular.desktop" ];
      "image/png" = [ "org.kde.gwenview.desktop" ];
      "image/jpeg" = [ "org.kde.gwenview.desktop" ];
      "image/webp" = [ "org.kde.gwenview.desktop" ];
      "image/gif" = [ "org.kde.gwenview.desktop" ];
      "image/svg+xml" = [ "org.kde.gwenview.desktop" ];
      "image/bmp" = [ "org.kde.gwenview.desktop" ];
      "image/tiff" = [ "org.kde.gwenview.desktop" ];
      
      # Directories
      "inode/directory" = [ "org.kde.dolphin.desktop" ];
    };
  };
}
