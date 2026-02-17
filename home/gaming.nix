{ pkgs, config, ... }:

let
  flashgbx = pkgs.callPackage ./flashgbx.nix { };
in
{
  home.packages = with pkgs; [
    # Custom
    flashgbx

    # Gaming Tools
    heroic
    lutris
    protonplus
    protonup-rs
    samrewritten
    cartridges
    piper
    openrgb
    goverlay
    vkbasalt
    input-remapper
    umu-launcher
    steamtinkerlaunch
    gamescope
    bottles
    
    # Wine / Windows Compatibility
    wineWowPackages.waylandFull # 32-bit + 64-bit Wine with Wayland support
    winetricks
    
    # Emulation
    unstable.dolphin-emu
    
    # Custom Script to fetch latest Conty
    (pkgs.writeShellScriptBin "update-conty" ''
      mkdir -p $HOME/.local/bin
      echo "Fetching latest Conty (Lite DwarFS) release URL..."
      LATEST_URL=$(curl -s https://api.github.com/repos/Kron4ek/Conty/releases/latest | ${pkgs.jq}/bin/jq -r '.assets[] | select(.name == "conty_lite_dwarfs.sh") | .browser_download_url')
      
      if [ -z "$LATEST_URL" ] || [ "$LATEST_URL" == "null" ]; then
        echo "Error: Could not find conty_lite_dwarfs.sh in the latest release."
        exit 1
      fi

      echo "Downloading from $LATEST_URL..."
      curl -L -o $HOME/.local/bin/conty "$LATEST_URL"
      chmod +x $HOME/.local/bin/conty
      
      echo "Successfully installed to $HOME/.local/bin/conty"
      echo "Run it with: conty"
    '')
  ];

  # Custom Desktop Entry for SAM Rewritten
  xdg.desktopEntries.samrewritten = {
    name = "Steam Achievement Manager";
    genericName = "Achievement Manager";
    exec = "samrewritten";
    terminal = false;
    categories = [ "Game" "Utility" ];
    icon = "samrewritten";
    comment = "Unlock Steam Achievements on Linux";
  };

  # Fetch the Eden Launcher icon
  home.file.".local/share/icons/hicolor/256x256/apps/eden-launcher.png".source = pkgs.fetchurl {
    url = "https://avatars.githubusercontent.com/u/205540286";
    hash = "sha256-9hzv7rKI4MSLp5icMB24AN6y5x4xzp/UTekkgsuoOoo=";
  };

  # Custom Desktop Entry for Eden Launcher (AppImage)
  xdg.desktopEntries.eden = {
    name = "Eden Launcher";
    genericName = "Game Launcher";
    exec = "steam-run ${config.home.homeDirectory}/.local/bin/Eden.AppImage";
    terminal = false;
    categories = [ "Game" ];
    icon = "eden-launcher"; 
    comment = "Modern open source game launcher";
  };

  # MangoHud Config
  programs.mangohud = {
    enable = true;
    settings = {
      # Visual Style (Catppuccin Mocha)
      text_color = "cdd6f4";
      gpu_color = "a6e3a1";  # Green
      cpu_color = "89b4fa";  # Blue
      vram_color = "f38ba8"; # Red
      ram_color = "fab387";  # Orange
      engine_color = "cba6f7"; # Mauve
      frametime_color = "94e2d5"; # Teal
      background_alpha = "0.4";
      font_size = 24;
      
      # The Data
      gpu_stats = true;
      gpu_temp = true;
      gpu_load_change = true; # Shows link speed jumps
      cpu_stats = true;
      cpu_temp = true;
      vram = true;
      ram = true;
      fps = true;
      frametime = true; # Stutter checking
      gamemode = false;
      
      # Layout
      table_columns = 3;
      frame_timing = 1;
    };
  };
}
