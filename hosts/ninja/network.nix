{ config, pkgs, ... }:

{
  networking = {
    hostName = "ninja";
    networkmanager.enable = true;
    networkmanager.unmanaged = [ "type:wifi" ];

    # --- STATIC IP CONFIGURATION ---
    interfaces.eno1.ipv4.addresses = [{
      address = "192.168.0.230";
      prefixLength = 24;
    }];

    defaultGateway = "192.168.0.1";

    # NextDNS
    nameservers = [ "45.90.28.154" "45.90.30.154" ];

    # --- FIREWALL ---
    firewall = {
      enable = true;
      # Open SSH or Steam ports here if needed
      allowedTCPPorts = [ 22 ]; 
    };
  };

  # Stop wpa_supplicant and ModemManager from running
  systemd.services.wpa_supplicant.enable = false;
  systemd.services.ModemManager.enable = false;
}