{ config, pkgs, lib, ... }:

{
  networking = {
    hostName = "ninja";
    useDHCP = false;
    useNetworkd = true;
    networkmanager.enable = lib.mkForce false;

    # --- FIREWALL ---
    firewall = {
      enable = true;
      # Open SSH or Steam ports here if needed
      allowedTCPPorts = [ 22 ]; 
    };
  };

  # --- SYSTEMD-NETWORKD CONFIGURATION ---
  systemd.network = {
    enable = true;
    networks."40-eno1" = {
      matchConfig.Name = "eno1";
      address = [ "192.168.0.230/24" ];
      routes = [{ Gateway = "192.168.0.1"; }];
      networkConfig.DNS = [ "192.168.0.96" ];
      linkConfig.RequiredForOnline = "routable";
    };
  };

  # Stop wpa_supplicant and ModemManager from running
  systemd.services.wpa_supplicant.enable = false;
  systemd.services.ModemManager.enable = false;
  programs.nm-applet.enable = false;
}
