{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Gaming Tools
    mangohud
    protonup-qt
    heroic
    lutris
    minigalaxy
    wineWowPackages.stable
    winetricks
    cartridges
    piper
    openrgb
    
    # Emulation
    (bottles.override { removeWarningPopup = true; })
  ];

  # MangoHud Config
  programs.mangohud = {
    enable = true;
    settings = {
      full = true;
      cpu_temp = true;
      gpu_temp = true;
      ram = true;
    };
  };
}
