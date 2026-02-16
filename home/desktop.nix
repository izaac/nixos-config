{ pkgs, ... }:

{
  # --- FONTS ---
  fonts.fontconfig.enable = true;
  
  catppuccin.zathura.enable = true;

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    font-awesome

    # Essential Tools
    telegram-desktop

    # Audio Tools
    pulsemixer

    # General Software
    fragments       # GTK Torrent Client
    amberol         # GTK Music Player
    brasero         # GTK CD/DVD Burning
    snapshot        # GTK Camera App
    sparrow
    celluloid       # GTK Frontend for MPV
    ffmpeg-full

    # CD/DVD Backup & Cloning
    cdrtools        # CLI: readcd, etc.
    cdrdao          # CLI: Disc-at-once cloning
    dvdisaster      # Error correction/data preservation
    ddrescue        # Robust data recovery

    # Virtualization (Distrobox Management)
    boxbuddy

    # GNOME Extensions & Integration
    nautilus-open-any-terminal

    # GTK Alternatives for Core Apps
    loupe           # GNOME Image Viewer
    file-roller     # GNOME Archive Manager
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
      "text/plain" = [ "org.gnome.TextEditor.desktop" ];
      "text/markdown" = [ "org.gnome.TextEditor.desktop" ];
      "text/x-log" = [ "org.gnome.TextEditor.desktop" ];

      # Archives
      "application/zip" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-tar" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-7z-compressed" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-rar" = [ "org.gnome.FileRoller.desktop" ];
      "application/gzip" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-bzip2" = [ "org.gnome.FileRoller.desktop" ];
      "application/x-xz" = [ "org.gnome.FileRoller.desktop" ];
      
      # Video
      "video/mp4" = [ "io.github.celluloid_player.Celluloid.desktop" ];
      "video/x-matroska" = [ "io.github.celluloid_player.Celluloid.desktop" ];
      "video/webm" = [ "io.github.celluloid_player.Celluloid.desktop" ];
      "video/quicktime" = [ "io.github.celluloid_player.Celluloid.desktop" ];
      
      # Audio
      "audio/mpeg" = [ "io.bassi.Amberol.desktop" ];
      "audio/flac" = [ "io.bassi.Amberol.desktop" ];
      "audio/x-wav" = [ "io.bassi.Amberol.desktop" ];
      
      # Documents / Images
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "application/epub+zip" = [ "org.pwmt.zathura.desktop" ];
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

  programs.zathura.enable = true;
}
