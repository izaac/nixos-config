{ pkgs, config, ... }:

let
  flashgbx = pkgs.callPackage ./flashgbx.nix { };
in
{
  home.packages = with pkgs; [
    # Custom
    flashgbx

    # Repack Support Tools
    fuse-overlayfs
    psmisc          # Provides 'fuser'
    bubblewrap      # Provides 'bwrap'

    # Gaming Tools
    heroic
    lutris
    protonplus
    protonup-rs
    samrewritten
    cartridges
    openrgb
    goverlay
    vkbasalt
    input-remapper
    umu-launcher
    steamtinkerlaunch
    gamescope
    (bottles.override { removeWarningPopup = true; })
    
    # Wine / Windows Compatibility
    wineWow64Packages.waylandFull # 32-bit + 64-bit Wine with Wayland support
    winetricks
    
    # Emulation
    dolphin-emu
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

  # MangoHud Config
  programs.mangohud = {    enable = true;
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
