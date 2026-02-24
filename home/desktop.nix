{ pkgs, userConfig, lib, ... }:

{
  imports = [
    ./distrobox.nix
    ./firefox.nix
    ./kitty.nix
    ./cava.nix
    ./cmus.nix
    ./qt.nix
    ./chromium.nix
    ./lazyvim.nix
    ./vscode.nix
    ./mpv.nix
  ];

  # --- FONTS ---
  fonts.fontconfig.enable = true;
  
  catppuccin.zathura.enable = true;

  services.easyeffects = {
    enable = true;
    preset = "nixos_audio";
  };
  
  xdg.dataFile."easyeffects/output/nixos_audio.json".source = ./audio-preset.json;

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    font-awesome

    # Essential Tools
    telegram-desktop
    ventoy-full-gtk

    # Audio Tools
    pulsemixer
    gnome-sound-recorder
    easyeffects

    # General Software
    fragments       # GTK Torrent Client
    amberol         # GTK Music Player
    brasero         # GTK CD/DVD Burning
    snapshot        # GTK Camera App
    sparrow
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
    gnomeExtensions.tiling-assistant

    # GTK Alternatives for Core Apps
    loupe           # GNOME Image Viewer
    file-roller     # GNOME Archive Manager
  ];

  xdg.userDirs = {
    enable = true;
    createDirectories = true; 
  };

  xdg.desktopEntries.playback = {
    name = "Playback";
    genericName = "GB Operator App";
    comment = "Play and manage Game Boy cartridges with Epilogue GB Operator (Gameboy, Epilogue, Operator, Nintendo)";
    exec = "appimage-run /home/${userConfig.username}/bin/playback";
    icon = "playback";
    terminal = false;
    categories = [ "Game" "Utility" ];
  };

  xdg.desktopEntries.ventoy = {
    name = "Ventoy";
    exec = "sudo ventoy-full-gtk";
    icon = "ventoy";
    terminal = false;
    categories = [ "Utility" "System" ];
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
      "video/mp4" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ];
      "video/webm" = [ "mpv.desktop" ];
      "video/quicktime" = [ "mpv.desktop" ];
      "video/x-flv" = [ "mpv.desktop" ];
      "video/x-msvideo" = [ "mpv.desktop" ];
      "video/mpeg" = [ "mpv.desktop" ];
      "video/ogg" = [ "mpv.desktop" ];
      "video/x-ogm+xml" = [ "mpv.desktop" ];
      "video/3gpp" = [ "mpv.desktop" ];
      "video/3gpp2" = [ "mpv.desktop" ];
      "video/h264" = [ "mpv.desktop" ];
      "video/mp2t" = [ "mpv.desktop" ];
      "video/vnd.rn-realvideo" = [ "mpv.desktop" ];
      "video/x-ms-wmv" = [ "mpv.desktop" ];
      
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

  # GNOME Performance & UX Tweaks
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      enable-animations = false;
    };
    "org/gnome/mutter" = {
      edge-tiling = true;
      dynamic-workspaces = true;
      workspaces-only-on-primary = true;
      experimental-features = [ "variable-refresh-rate" ];
    };
    "org/gnome/shell" = {
      disable-user-extensions = false;
    };
    "org/gnome/shell/app-switcher" = {
      current-workspace-only = true;
    };
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "nothing";
      idle-dim = false;
    };
    "org/gnome/desktop/session" = {
      idle-delay = lib.hm.gvariant.mkUint32 3600;
    };
    "org/gnome/desktop/screensaver" = {
      lock-enabled = true;
    };

    # Default Terminal & Keybinding
    "org/gnome/desktop/default-applications/terminal" = {
      exec = "kitty";
      exec-arg = "-e";
    };
    "org/gnome/settings-daemon/plugins/media-keys" = {
      custom-keybindings = [ 
        "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/" 
      ];
    };
    "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
      binding = "<Control><Alt>t";
      command = "kitty";
      name = "Terminal";
    };

    # Nautilus Open Any Terminal Configuration
    "com/github/stefonh/nautilus-open-any-terminal" = {
      terminal = "kitty";
      new-window = false;
    };
  };
}
