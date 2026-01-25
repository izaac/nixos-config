{ config, pkgs, ... }:

{
  imports = [
    ./kitty.nix
    ./starship.nix
    ./bash.nix
    ./vimrc.nix
    ./gnome-extensions.nix
  ];
  home.username = "izaac";
  home.homeDirectory = "/home/izaac";

  # Match this to your system's stateVersion (25.11)
  home.stateVersion = "25.11"; 

  # Let Home Manager install itself
  programs.home-manager.enable = true;

  # This is where we'll add your "gadgets" and tools
  home.packages = with pkgs; [
    btop      # Better system monitor for your 5070 Ti
    fastfetch # Shows system info + GPU in terminal
    eza       # Modern 'ls' replacement (very clean)
    vscode
    _7zz
    zip
    unzip
    nerd-fonts.jetbrains-mono
    kitty
    distrobox
    boxbuddy
    bottles
    gcc
    gnumake
    xorg.xhost
    pika-backup       # Simple Backups
    textsnatcher      # OCR from Screen
    resources         # Modern Task Manager
    fragments         # Torrenting
    cartridges

    # Entertainment
    jellyfin-desktop
    jellytui
    amberol

    # Gaming Tools
    mangohud      # The FPS/GPU overlay
    protonup-qt   # GUI to install "Proton GE" (fixes many games)
  ];

  programs.mpv = {
    enable = true;
    
    # Scripts to make it feel like a modern app
    scripts = with pkgs.mpvScripts; [
      mpris       # Allows Gnome media keys (Play/Pause) to control MPV
      uosc        # A minimalist, modern UI (replaces the ugly 2005 OSD)
      thumbfast   # Instant thumbnails on the seekbar
    ];

    config = {
      # --- Video & Acceleration ---
      # "auto-safe" prioritizes NVDEC (Nvidia native) or VAAPI based on what works best
      hwdec = "auto-safe"; 
      
      # The modern Vulkan-based renderer. 
      # Much better scaling and HDR handling than the old "gpu" output.
      vo = "gpu-next";
      
      # Use "gpu-hq" as a base (high quality scaling algorithms)
      profile = "gpu-hq";
      
      # Force Wayland context (avoids XWayland blur)
      gpu-context = "wayland";

      # --- Quality of Life ---
      save-position-on-quit = true;
      keep-open = "yes";              # Don't close the window when the video ends
      
      # Smooth motion (optional, remove if you hate the "soap opera" effect)
      # video-sync = "display-resample";
      # interpolation = true;
      # tscale = "oversample";
    };
  };

  programs.mangohud = {
    enable = true;
    
    # Optional: Configure the look right here so you don't need a config file
    settings = {
      full = true;
      cpu_temp = true;
      gpu_temp = true;
      ram = true;
    };
  };

  programs.bash = {
    enable = true;
    historySize = 10000;
    historyFileSize = 100000;
    historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
  
    # The "Pro" tweaks
    initExtra = ''
      # Append to history instead of overwriting
      shopt -s histappend
      # Save history after every command (don't wait for exit)
      PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
    '';
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "izaac";
        email = "jorge.izaac@gmail.com";
      };
    };
  };

  programs.ssh = {
    enable = true;
    
    # Silence the warning by explicitly managing defaults yourself
    enableDefaultConfig = false; 

    matchBlocks = {
      "*" = {
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  services.ssh-agent.enable = true;

  home.file.".config/autostart/fix-gparted-wayland.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Fix GParted Wayland
    Comment=Allow root to access display
    # The magic command
    Exec=${pkgs.xorg.xhost}/bin/xhost +SI:localuser:root
    X-GNOME-Autostart-enabled=true
    Hidden=false
    NoDisplay=true
  '';
}

