{ config, pkgs, lib, ... }:

{
  networking = {
    hostName = "ninja";
    useDHCP = false;
    networkmanager.enable = lib.mkForce false;

    # --- STATIC IP CONFIGURATION ---
    interfaces.eno1.ipv4.addresses = [{
      address = "192.168.0.230";
      prefixLength = 24;
    }];

    defaultGateway = "192.168.0.1";

    # Local DNS
    nameservers = [ "192.168.0.96" ];

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
  programs.nm-applet.enable = false;
}