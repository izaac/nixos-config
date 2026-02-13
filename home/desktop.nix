{ pkgs, ... }:

{
  # --- FONTS ---
  fonts.fontconfig.enable = true;
  
  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    font-awesome

    # Essential Tools
    telegram-desktop

    # Audio Tools
    pulsemixer

    # General Software
    qbittorrent
    kdePackages.elisa  # Simple Music Player
    kdePackages.k3b    # CD/DVD/Blu-ray Burning & Ripping
    kdePackages.kamoso # Camera App
    sparrow
    # filezilla       # Removed (not KDE/Qt)
    vlc
    zathura         # Minimalist PDF viewer
    ffmpeg-full
    jellyfin-desktop

    # CD/DVD Backup & Cloning
    cdrtools        # CLI: readcd, etc.
    cdrdao          # CLI: Disc-at-once cloning
    dvdisaster      # Error correction/data preservation
    ddrescue        # Robust data recovery

    # Virtualization (Distrobox Management)
    boxbuddy

    # Core KDE Apps (Ensured in system config, managed here for user context)
    kdePackages.kate      # Advanced Text Editor (Includes KWrite)
    kdePackages.gwenview  # Image Viewer
    kdePackages.ark       # Archive Manager
    kdePackages.dolphin   # File Manager
    kdePackages.okular    # Document Viewer
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
      "video/mp4" = [ "vlc.desktop" ];
      "video/x-matroska" = [ "vlc.desktop" ];
      "video/webm" = [ "vlc.desktop" ];
      "video/quicktime" = [ "vlc.desktop" ];
      
      # Audio
      "audio/mpeg" = [ "org.kde.elisa.desktop" ];
      "audio/flac" = [ "org.kde.elisa.desktop" ];
      "audio/x-wav" = [ "org.kde.elisa.desktop" ];
      
      # Documents / Images
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "application/epub+zip" = [ "org.pwmt.zathura.desktop" ];
      "image/png" = [ "org.kde.gwenview.desktop" ];
      "image/jpeg" = [ "org.kde.gwenview.desktop" ];
      "image/webp" = [ "org.kde.gwenview.desktop" ];
      "image/gif" = [ "org.kde.gwenview.desktop" ];
      "image/svg+xml" = [ "org.kde.gwenview.desktop" ];
      "image/bmp" = [ "org.kde.gwenview.desktop" ];
      "image/tiff" = [ "org.kde.gwenview.desktop" ];
      
      # Directories
      "inode/directory" = [ "org.kde.dolphin.desktop" ];

      # AppImages / Executables
      "application/vnd.appimage" = [ "steam-runner.desktop" ];
      "application/x-executable" = [ "steam-runner.desktop" ];
    };
  };
}
