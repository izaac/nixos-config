{
  pkgs,
  inputs,
  ...
}: let
  nix-packages = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [
    ./distrobox.nix
    ./wezterm.nix
    ./cava.nix
    ./cmus.nix
    ./qt.nix
    ./chrome.nix
    ./helix.nix
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
    nix-packages.ethereal-waves # COSMIC Music Player

    # General Software
    gophertube # TUI YouTube Client
    chafa # Terminal Graphics for gophertube
    fragments # GTK Torrent Client (Rust)
    clapper # Modern GTK4 Video Player (Rust)
    snapshot # GTK Camera App (Rust)
    sparrow
    ffmpeg-full

    # COSMIC Extensions & Integration
    cosmic-applets # Official System76 applet bundle

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
    papers # PDF/Document Viewer (Rust)
    mission-center # System Monitor (Rust)
    file-roller # Archive Manager
    newsflash # GTK4/Libadwaita RSS Reader (Rust)
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
      icon = "ventoy";
      terminal = false;
      categories = ["Utility" "System"];
    };

    # Default Applications (File Associations)
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = ["chromium-browser.desktop"];
        "x-scheme-handler/http" = ["chromium-browser.desktop"];
        "x-scheme-handler/https" = ["chromium-browser.desktop"];
        "x-scheme-handler/about" = ["chromium-browser.desktop"];
        "x-scheme-handler/unknown" = ["chromium-browser.desktop"];

        # Text
        "text/plain" = ["com.system76.CosmicEdit.desktop"];
        "text/markdown" = ["com.system76.CosmicEdit.desktop"];
        "text/x-log" = ["com.system76.CosmicEdit.desktop"];

        # Archives
        "application/zip" = ["com.system76.CosmicFiles.desktop"];
        "application/x-tar" = ["com.system76.CosmicFiles.desktop"];
        "application/x-7z-compressed" = ["com.system76.CosmicFiles.desktop"];
        "application/x-rar" = ["com.system76.CosmicFiles.desktop"];
        "application/gzip" = ["com.system76.CosmicFiles.desktop"];
        "application/x-bzip2" = ["com.system76.CosmicFiles.desktop"];
        "application/x-xz" = ["com.system76.CosmicFiles.desktop"];

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

        # Audio
        "audio/mpeg" = ["org.gnome.Amberol.desktop"];
        "audio/flac" = ["org.gnome.Amberol.desktop"];
        "audio/x-wav" = ["org.gnome.Amberol.desktop"];

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

        # Directories (COSMIC Files)
        "inode/directory" = ["com.system76.CosmicFiles.desktop"];
      };
    };
  };

  services.udiskie.enable = true;

  # Clipboard History Watcher (stores clipboard entries for recall)
  systemd.user.services.cliphist-watcher = {
    Unit = {
      Description = "Clipboard history watcher";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  dconf.settings = {
    # Tracker indexing limits (still used by some GTK apps)
    "org/freedesktop/Tracker3/Miner/Files" = {
      index-recursive-directories = [];
      index-single-directories = [];
      ignored-directories = ["&DESKTOP" "&DOCUMENTS" "&DOWNLOAD" "&MUSIC" "&PICTURES" "&PUBLIC_SHARE" "&TEMPLATES" "&VIDEOS"];
    };
  };
}
