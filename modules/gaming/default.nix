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

  # 4. Bluetooth Tweaks
  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings = {
    General = {
      Enable = "Source,Sink,Media,Socket";
      Experimental = true;
    };
  };

  # 5. Environment Tweaks
  environment.sessionVariables = {
    # Helps Steam find the NVIDIA driver in the FHS container
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/izaac/.steam/root/compatibilitytools.d";
  };
}
