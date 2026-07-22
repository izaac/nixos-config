{
  pkgs,
  inputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
in {
  imports = [
    ./distrobox.nix
    ./kitty.nix
    ./cava.nix
    ./cmus.nix
    ./abcde.nix
    ./qt.nix
    ./chrome.nix

    ./lazyvim.nix
    ./vscode.nix
    ./capture-card.nix
    ./firefox.nix
  ];

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
    monophony
    amberol # Simple Rust Music Player
    shortwave # Rust Internet Radio
    gnome-sound-recorder # Audio Recorder

    # General Software
    fragments # GTK Torrent Client (Rust)
    clapper # Modern GTK4 Video Player (Rust)
    vlc # General media player; also a DLNA/UPnP client for the Plex library
    mpv # Low-latency player (good for capture card live view)
    snapshot # GTK Camera App (Rust)
    inputs.nix-packages.packages.${system}.sparrow
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

    # Default Applications (File Associations)
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = ["firefox.desktop"];
        "x-scheme-handler/http" = ["firefox.desktop"];
        "x-scheme-handler/https" = ["firefox.desktop"];
        "x-scheme-handler/about" = ["firefox.desktop"];
        "x-scheme-handler/unknown" = ["firefox.desktop"];

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

  services.udiskie = {
    enable = true;
    settings = {
      program_options = {
        file_manager = "nemo";
      };
    };
  };

  # Suppress xdg-autostart for the GVFS volume monitor; Noctalia owns the
  # tray, network, bluetooth, and audio surfaces, so the old tray applets are
  # no longer installed or autostarted.
  xdg.configFile = let
    hidden = ''
      [Desktop Entry]
      Type=Application
      Hidden=true
    '';
  in {
    "autostart/gvfs-goa-volume-monitor.desktop".text = hidden;
  };
}
