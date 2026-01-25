{ pkgs, ... }:

{
  # 1. Steam Hardware Support
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  # 2. GameMode (MOVED HERE from Home Manager)
  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings = {
      general = {
        renice = 10;
      };
    };
  };

  # 3. Controller & Hardware Support
  hardware.xpadneo.enable = true;
  
  services.udev.packages = with pkgs; [
    game-devices-udev-rules 
    logitech-udev-rules
  ];

  # 4. Bluetooth Tweaks
  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings = {
    General = {
      Enable = "Source,Sink,Media,Socket";
      Experimental = true;
    };
  };
}
