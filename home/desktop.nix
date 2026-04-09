{
  pkgs,
  inputs,
  ...
}: let
  nix-packages = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [
    ./distrobox.nix
    ./firefox.nix
    ./wezterm.nix
    ./cava.nix
    ./cmus.nix
    ./qt.nix
    ./chrome.nix
    ./lazyvim.nix
    ./vscode.nix
  ];

  # --- FONTS ---
  fonts.fontconfig.enable = true;

  catppuccin.zathura.enable = true;

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
    nix-packages.ethereal-waves # COSMIC Music Player

    # General Software
    abiword # Lightweight GTK Word Processor
    gophertube # TUI YouTube Client
    chafa # Terminal Graphics for gophertube
    fragments # GTK Torrent Client
    glide-media-player # GTK Video Player
    brasero # GTK CD/DVD Burning
    snapshot # GTK Camera App
    sparrow
    ffmpeg-full

    # CD/DVD Backup & Cloning
    cdrtools # CLI: readcd, etc.
    cdrdao # CLI: Disc-at-once cloning
    dvdisaster # Error correction/data preservation
    ddrescue # Data recovery

    # Virtualization (Distrobox Management)
    boxbuddy
    gearlever

    # GTK Apps
    loupe # Image Viewer
    file-roller # Archive Manager
    newsflash # GTK4/Libadwaita RSS Reader
  ];

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    setSessionVariables = false;
  };
  xdg.desktopEntries.ventoy = {
    name = "Ventoy";
    exec = "sudo ventoy-full-gtk";
    icon = "ventoy";
    terminal = false;
    categories = ["Utility" "System"];
  };

  # Default Applications (File Associations)
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = ["firefox.desktop"];
      "x-scheme-handler/http" = ["firefox.desktop"];
      "x-scheme-handler/https" = ["firefox.desktop"];
      "x-scheme-handler/about" = ["firefox.desktop"];
      "x-scheme-handler/unknown" = ["firefox.desktop"];

      # Text
      "text/plain" = ["com.system76.CosmicEdit.desktop"];
      "text/markdown" = ["com.system76.CosmicEdit.desktop"];
      "text/x-log" = ["com.system76.CosmicEdit.desktop"];

      # Archives
      "application/zip" = ["org.gnome.FileRoller.desktop"];
      "application/x-tar" = ["org.gnome.FileRoller.desktop"];
      "application/x-7z-compressed" = ["org.gnome.FileRoller.desktop"];
      "application/x-rar" = ["org.gnome.FileRoller.desktop"];
      "application/gzip" = ["org.gnome.FileRoller.desktop"];
      "application/x-bzip2" = ["org.gnome.FileRoller.desktop"];
      "application/x-xz" = ["org.gnome.FileRoller.desktop"];

      # Video
      "video/mp4" = ["dev.philn.Glide.desktop"];
      "video/x-matroska" = ["dev.philn.Glide.desktop"];
      "video/webm" = ["dev.philn.Glide.desktop"];
      "video/quicktime" = ["dev.philn.Glide.desktop"];
      "video/x-flv" = ["dev.philn.Glide.desktop"];
      "video/x-msvideo" = ["dev.philn.Glide.desktop"];
      "video/mpeg" = ["dev.philn.Glide.desktop"];
      "video/ogg" = ["dev.philn.Glide.desktop"];
      "video/x-ogm+xml" = ["dev.philn.Glide.desktop"];
      "video/3gpp" = ["dev.philn.Glide.desktop"];
      "video/3gpp2" = ["dev.philn.Glide.desktop"];
      "video/h264" = ["dev.philn.Glide.desktop"];
      "video/mp2t" = ["dev.philn.Glide.desktop"];
      "video/vnd.rn-realvideo" = ["dev.philn.Glide.desktop"];
      "video/x-ms-wmv" = ["dev.philn.Glide.desktop"];

      # Audio
      "audio/mpeg" = ["com.galacticpirateradio.ethereal-waves.desktop"];
      "audio/flac" = ["com.galacticpirateradio.ethereal-waves.desktop"];
      "audio/x-wav" = ["com.galacticpirateradio.ethereal-waves.desktop"];

      # Documents / Images
      "application/pdf" = ["org.pwmt.zathura.desktop"];
      "application/epub+zip" = ["org.pwmt.zathura.desktop"];
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

  programs.zathura.enable = true;
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
