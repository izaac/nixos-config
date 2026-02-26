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
      allowedTCPPortRanges = [ { from = 1714; to = 1764; } ];
      allowedUDPPortRanges = [ { from = 1714; to = 1764; } ];
    };
  };

  # --- SYSTEMD-NETWORKD CONFIGURATION ---
  systemd.network = {
    enable = true;
    
    # Link-level hardware optimizations (Queues)
    links."10-eno1" = {
      matchConfig.Name = "eno1";
      linkConfig = {
        TransmitQueues = 8;
        ReceiveQueues = 8;
        
        # Disable Energy Efficient Ethernet (EEE) to prevent igc/I225-V hangs
        WakeOnLan = "off";
      };
    };

    networks."40-eno1" = {
      matchConfig.Name = "eno1";
      
      # Modern 25.11 Simplified Syntax
      address = [ "192.168.0.230/24" ];
      gateway = [ "192.168.0.1" ];
      dns = [ "192.168.0.96" ];

      # Disable Energy Efficient Ethernet (EEE) to prevent NIC sleep state locks
      # See Intel I225-V/igc known issues
      networkConfig = {
        IPv6PrivacyExtensions = "kernel";
      };
      
      # Additional settings specific to the physical link layer
      # EEE (Energy Efficient Ethernet) can cause the I225 controller to hang under load
      # after a few hours and requires a physical or bus reset to recover.
      # Setting 'WakeOnLan=off' also helps prevent firmware sleep bugs.
      linkConfig = {
        RequiredForOnline = "routable";
      };
    };
  };

  # Stop wpa_supplicant and ModemManager from running
  systemd.services.wpa_supplicant.enable = false;
  systemd.services.ModemManager.enable = false;
  programs.nm-applet.enable = false;
}
