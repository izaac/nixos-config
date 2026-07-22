{lib, ...}: {
  networking = {
    hostName = "ninja";
    useDHCP = false;
    useNetworkd = true;
    nftables.enable = true;
    networkmanager.enable = lib.mkForce false;

    # --- FIREWALL ---
    firewall = {
      enable = true;
      # Open SSH or Steam ports here if needed
      allowedTCPPorts = [];
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      # Trust the local NAS/Plex server (NFS callbacks and discovery)
      #
      # Allow container DNS (aardvark-dns) on every Podman/netavark bridge.
      # NixOS only auto-opens port 53 on the default `podman0` bridge, so any
      # additional network (podman1, podman2, k3d-created bridges, ...) has its
      # container->gateway DNS queries silently dropped by the `policy drop`
      # INPUT chain. This breaks container-name resolution (e.g. k3d's serverlb
      # nginx resolving `k3d-<cluster>-server-0`). The `podman*` wildcard covers
      # all current and future netavark bridges.
      # Allow the LAN to reach VLC's Chromecast stream server (default TCP
      # 8010) so casting a video to the Sony Bravia works. VLC serves the
      # file over HTTP and the TV connects back to fetch it; the default
      # drop policy would otherwise block that inbound connection.
      extraInputRules = ''
        ip saddr 192.168.0.173 accept
        iifname "podman*" udp dport 53 accept
        iifname "podman*" tcp dport 53 accept
        ip saddr 192.168.0.0/24 tcp dport 8010 accept
      '';
    };
  };

  # Stop wpa_supplicant and ModemManager from running
  systemd = {
    network = {
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
        address = ["192.168.0.230/24"];
        gateway = ["192.168.0.1"];
        dns = ["192.168.0.96"];
        domains = ["~."]; # Route ALL DNS traffic through this interface (Pi-hole)

        # Ignore DNS from the router to prevent bypassing Pi-hole
        dhcpV4Config.UseDNS = false;
        dhcpV6Config.UseDNS = false;
        ipv6AcceptRAConfig.UseDNS = false;

        # Disable Energy Efficient Ethernet (EEE) to prevent NIC sleep state locks
        # See Intel I225-V/igc known issues
        networkConfig = {
          IPv6PrivacyExtensions = "kernel";
          MulticastDNS = false;
          LLMNR = false;
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

    services.wpa_supplicant.enable = false;

    # Only wait for eno1 (static IP) — don't block boot on all interfaces
    network.wait-online = {
      anyInterface = true;
      timeout = 5;
    };
  };
  programs.nm-applet.enable = false;

  # Intel I225-V/I226-V (igc) Latency Optimization
  # InterruptThrottleRate=0 disables throttling, ensuring the NIC interrupts the CPU immediately.
  boot.extraModprobeConfig = ''
    options igc InterruptThrottleRate=0,0,0,0
  '';

  # --- DNS CONFIGURATION ---
  # Using systemd-resolved but DISABLING DNSSEC.
  # Local DNS (Pi-hole) often strips signatures, causing validation hangs.
  #
  # Cache=no-negative: do not cache NXDOMAIN/negative answers. Ephemeral
  # hostnames (cloudflared quick tunnels *.trycloudflare.com, wildcard
  # *.sslip.io, *.qa.rancher.space) are queried the instant they are created,
  # before the upstream record has propagated. A cached negative answer would
  # then persist for the SOA negative TTL and make the name appear permanently
  # unresolvable to getent/NSS even after propagation. Disabling negative
  # caching lets each lookup re-query Pi-hole, which resolves these fine.
  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNSSEC = "no";
      Cache = "no-negative";
    };
  };
}
