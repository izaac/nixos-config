{ pkgs, ... }:

{
  # 1. Steam Hardware Support
  # Explicitly enables udev rules for Valve hardware
  hardware.steam-hardware.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true; # Adds "Steam Deck" session support
    extraCompatPackages = [ pkgs.steamtinkerlaunch ];
    extraPackages = with pkgs; [
      libvdpau
      libva
      mangohud
      protonup-qt
    ];
  };

  # 2. GameMode
  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings = {
      general = {
        renice = 10;
      };
    };
  };

  # 3. Controller & Hardware Support (The "Maximized" List)
  hardware.xpadneo.enable = true; # Xbox Bluetooth
  services.joycond.enable = true; # Nintendo Switch JoyCons (Merge L+R)
  hardware.uinput.enable = true;  # Virtual Input (Critical for remapping tools)
  
  services.udev.packages = with pkgs; [
    game-devices-udev-rules # The big community list
    logitech-udev-rules
    openrgb                 # RGB Control access
  ];

  # 5. Environment Tweaks
  environment.sessionVariables = {
    # Force NVIDIA for Steam (fixes the iGPU vs dGPU conflict)
    __NV_PRIME_RENDER_OFFLOAD = "1";
    __NV_PRIME_RENDER_OFFLOAD_SET_AS_ID = "0";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };
}
