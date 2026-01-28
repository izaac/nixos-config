{ pkgs, ... }:

let
  flashgbx = pkgs.callPackage ./flashgbx.nix { };
in
{
  home.packages = with pkgs; [
    # Custom
    flashgbx

    # Gaming Tools
    protonup-qt
    heroic
    lutris
    minigalaxy
    wineWowPackages.stable
    winetricks
    cartridges
    piper
    openrgb
    goverlay
    vkbasalt
    input-remapper
    umu-launcher
    
    # Emulation
    (bottles.override { removeWarningPopup = true; })
  ];

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
      
      # Layout
      table_columns = 3;
      frame_timing = 1;
    };
  };
}
