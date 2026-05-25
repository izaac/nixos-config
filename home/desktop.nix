{pkgs, ...}: {
  imports = [
    ./distrobox.nix
    ./ghostty.nix
    ./cava.nix
    ./cmus.nix
    ./abcde.nix
    ./qt.nix
    ./chrome.nix
    ./lazyvim.nix
    ./vscode.nix
  ];

  # --- FONTS ---
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    font-awesome

    # Essential Tools
    telegram-desktop
    ventoy-full-gtk

    # Audio Tools
    pulsemixer
    monophony
    amberol # Simple Rust Music Player
    shortwave # Rust Internet Radio

    # General Software
    fragments # GTK Torrent Client (Rust)
    clapper # Modern GTK4 Video Player (Rust)
    snapshot # GTK Camera App (Rust)
    sparrow
    ffmpeg-full

    # File manager + archives + preview thumbnailers
    nemo-with-extensions # Nemo + bundled extensions (image preview, etc.)
    nemo-fileroller # Archive context-menu integration
    file-roller # Archive manager
    ffmpegthumbnailer # Video thumbnails for Nemo
    webp-pixbuf-loader # WebP image thumbnails

    # GUI text editor (honors GNOME prefer-dark via dconf)
    gnome-text-editor

    # CD/DVD Backup & Cloning
    cdrtools # CLI: readcd, etc.
    cdrdao # CLI: Disc-at-once cloning
    dvdisaster # Error correction/data preservation
    ddrescue # Data recovery

    # Virtualization (Distrobox Management)
    boxbuddy
    gearlever

    # GTK Apps (Rust-based replacements)
    loupe # Image Viewer (Rust)
    (papers.override {supportNautilus = false;}) # PDF/Document Viewer (Rust)
    newsflash # GTK4/Libadwaita RSS Reader (Rust)
    drawing # GTK image editor (MS Paint-like)
    gnome-calculator # GTK4/libadwaita scientific + programming calculator
  ];

  xdg = {
    userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = false;
    };
    desktopEntries.ventoy = {
      name = "Ventoy";
      exec = "sudo ventoy-full-gtk";
      icon = "drive-removable-media-usb";
      terminal = false;
      categories = ["Utility" "System"];
    };

    # Default Applications (File Associations)
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = ["brave-origin.desktop"];
        "x-scheme-handler/http" = ["brave-origin.desktop"];
        "x-scheme-handler/https" = ["brave-origin.desktop"];
        "x-scheme-handler/about" = ["brave-origin.desktop"];
        "x-scheme-handler/unknown" = ["brave-origin.desktop"];

        # Text
        "text/plain" = ["org.gnome.TextEditor.desktop"];
        "text/markdown" = ["org.gnome.TextEditor.desktop"];
        "text/x-log" = ["org.gnome.TextEditor.desktop"];

        # Archives (file-roller)
        "application/zip" = ["org.gnome.FileRoller.desktop"];
        "application/x-tar" = ["org.gnome.FileRoller.desktop"];
        "application/x-7z-compressed" = ["org.gnome.FileRoller.desktop"];
        "application/x-rar" = ["org.gnome.FileRoller.desktop"];
        "application/gzip" = ["org.gnome.FileRoller.desktop"];
        "application/x-bzip2" = ["org.gnome.FileRoller.desktop"];
        "application/x-xz" = ["org.gnome.FileRoller.desktop"];

        # Video
        "video/mp4" = ["com.github.rafostar.Clapper.desktop"];
        "video/x-matroska" = ["com.github.rafostar.Clapper.desktop"];
        "video/webm" = ["com.github.rafostar.Clapper.desktop"];
        "video/quicktime" = ["com.github.rafostar.Clapper.desktop"];
        "video/x-flv" = ["com.github.rafostar.Clapper.desktop"];
        "video/x-msvideo" = ["com.github.rafostar.Clapper.desktop"];
        "video/mpeg" = ["com.github.rafostar.Clapper.desktop"];
        "video/ogg" = ["com.github.rafostar.Clapper.desktop"];
        "video/x-ogm+xml" = ["com.github.rafostar.Clapper.desktop"];
        "video/3gpp" = ["com.github.rafostar.Clapper.desktop"];
        "video/3gpp2" = ["com.github.rafostar.Clapper.desktop"];
        "video/h264" = ["com.github.rafostar.Clapper.desktop"];
        "video/mp2t" = ["com.github.rafostar.Clapper.desktop"];
        "video/vnd.rn-realvideo" = ["com.github.rafostar.Clapper.desktop"];
        "video/x-ms-wmv" = ["com.github.rafostar.Clapper.desktop"];

        # Audio (Amberol)
        "audio/mpeg" = ["io.bassi.Amberol.desktop"];
        "audio/flac" = ["io.bassi.Amberol.desktop"];
        "audio/x-wav" = ["io.bassi.Amberol.desktop"];
        "audio/ogg" = ["io.bassi.Amberol.desktop"];
        "audio/x-vorbis+ogg" = ["io.bassi.Amberol.desktop"];
        "audio/mp4" = ["io.bassi.Amberol.desktop"];
        "audio/x-flac" = ["io.bassi.Amberol.desktop"];
        "audio/x-mp3" = ["io.bassi.Amberol.desktop"];

        # Documents / Images
        "application/pdf" = ["org.gnome.Papers.desktop"];
        "application/epub+zip" = ["org.gnome.Papers.desktop"];
        "image/png" = ["org.gnome.Loupe.desktop"];
        "image/jpeg" = ["org.gnome.Loupe.desktop"];
        "image/webp" = ["org.gnome.Loupe.desktop"];
        "image/gif" = ["org.gnome.Loupe.desktop"];
        "image/svg+xml" = ["org.gnome.Loupe.desktop"];
        "image/bmp" = ["org.gnome.Loupe.desktop"];
        "image/tiff" = ["org.gnome.Loupe.desktop"];

        # Directories (Nemo)
        "inode/directory" = ["nemo.desktop"];
      };
    };
  };

  services.udiskie.enable = true;

  # Suppress xdg-autostart for tray apps: niri's spawn-at-startup launches
  # blueman + nm-applet directly, and pasystray runs on-demand from waybar.
  # The systemd-xdg-autostart-generator otherwise double-starts them and
  # fails because the first instance already owns the tray slot.
  xdg.configFile = let
    hidden = ''
      [Desktop Entry]
      Type=Application
      Hidden=true
    '';
  in {
    "autostart/gvfs-goa-volume-monitor.desktop".text = hidden;
    "autostart/blueman.desktop".text = hidden;
    "autostart/nm-applet.desktop".text = hidden;
    "autostart/pasystray.desktop".text = hidden;
  };
}
