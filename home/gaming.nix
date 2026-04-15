{
  pkgs,
  lib,
  userConfig,
  inputs,
  ...
}: let
  flashgbx = pkgs.callPackage ./flashgbx.nix {};
  nix-packages = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system};
in {
  home.packages = with pkgs; [
    # Custom
    flashgbx
    nix-packages.zelda-oot

    # Repack Support Tools
    fuse-overlayfs
    psmisc # Provides 'fuser'
    bubblewrap # Provides 'bwrap'

    # Gaming Tools
    heroic
    lutris
    protonup-rs
    samrewritten
    cartridges
    openrgb
    goverlay
    vkbasalt
    umu-launcher
    gamescope
    (bottles.override {removeWarningPopup = true;})

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
    categories = ["Game" "Utility"];
    icon = "samrewritten";
    comment = "Unlock Steam Achievements on Linux";
  };

  # Custom Desktop Entry for Ocarina of Time (Native Port)
  xdg.desktopEntries.zelda-oot = {
    name = "The Legend of Zelda: Ocarina of Time";
    genericName = "Zelda: Ocarina of Time (Native Port)";
    exec = "launch-zelda-oot";
    terminal = false;
    categories = ["Game"];
    icon = "/home/${userConfig.username}/Games/ZeldaOOT/icon.png";
    comment = "Native Linux port of Ocarina of Time (Ship of Harkinian)";
  };

  # MangoHud Config
  programs.mangohud = {
    enable = true;
    settings = {
      background_alpha = lib.mkForce 0.4;
      font_size = lib.mkForce 24;

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
      gamemode = true;

      # Layout
      table_columns = 3;
      frame_timing = 1;
    };
  };
}
