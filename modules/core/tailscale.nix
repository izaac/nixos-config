{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.mySystem.core.tailscale;
in {
  options.mySystem.core.tailscale = {
    enable = lib.mkEnableOption "Tailscale mesh VPN with Tailscale SSH";

    advertiseRoutes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["192.168.0.0/24"];
      description = ''
        Subnet CIDRs this host advertises to the tailnet, turning it into a
        subnet router. Routes must also be approved once in the Tailscale
        admin console. Leave empty for a plain (non-routing) node.
      '';
    };

    routingInterface = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "eno1";
      description = ''
        Physical interface that carries routed traffic. When this host
        advertises routes, UDP GRO forwarding is enabled on it (Tailscale's
        recommended tuning for subnet-router/exit-node throughput). Null skips
        the tuning.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      # Opens the WireGuard UDP port (services.tailscale.port) in the firewall.
      openFirewall = true;
      # "server" enables IP forwarding sysctls so this node can route the
      # advertised subnet for the rest of the tailnet.
      useRoutingFeatures =
        if cfg.advertiseRoutes != []
        then "server"
        else "client";
      # Flags applied on `tailscale up`. --ssh enables Tailscale SSH (auth via
      # tailnet ACLs, no extra ports). --accept-dns=false keeps this host on its
      # local Pi-hole resolver instead of MagicDNS.
      extraUpFlags =
        ["--ssh" "--accept-dns=false"]
        ++ lib.optional (cfg.advertiseRoutes != [])
        "--advertise-routes=${lib.concatStringsSep "," cfg.advertiseRoutes}";
    };

    # Subnet routing across the tailscale0 interface needs loose reverse-path
    # filtering, and the interface itself must be trusted by the firewall.
    networking.firewall = {
      checkReversePath = "loose";
      trustedInterfaces = ["tailscale0"];
    };

    # modules/core/performance.nix forces strict kernel rp_filter (=1) globally
    # for anti-spoof hardening. On a subnet router that silently drops the
    # asymmetric tailnet<->LAN return paths this node is meant to forward, so
    # relax it to loose (=2) only when this host actually advertises routes.
    # Loose still rejects spoofed sources but permits valid asymmetric routing.
    # mkOverride 49 wins over the shared module's mkForce (priority 50).
    boot.kernel.sysctl = lib.mkIf (cfg.advertiseRoutes != []) {
      "net.ipv4.conf.all.rp_filter" = lib.mkOverride 49 2;
      "net.ipv4.conf.default.rp_filter" = lib.mkOverride 49 2;
    };

    # This host uses the nftables backend; tell tailscaled to match.
    systemd.services.tailscaled.serviceConfig.Environment = [
      "TS_DEBUG_FIREWALL_MODE=nftables"
    ];

    # Subnet routers/exit nodes get a big UDP forwarding throughput boost from
    # enabling rx-udp-gro-forwarding on the carrying NIC. Only meaningful when
    # this host actually routes traffic.
    systemd.services.tailscale-udp-gro = lib.mkIf (cfg.advertiseRoutes != [] && cfg.routingInterface != null) {
      description = "Enable UDP GRO forwarding on ${cfg.routingInterface} for Tailscale routing";
      after = ["sys-subsystem-net-devices-${cfg.routingInterface}.device"];
      bindsTo = ["sys-subsystem-net-devices-${cfg.routingInterface}.device"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.ethtool}/bin/ethtool -K ${cfg.routingInterface} rx-udp-gro-forwarding on rx-gro-list off";
        NoNewPrivileges = true;
        ProtectHome = true;
        ProtectSystem = "strict";
      };
    };

    # Catch a half-configured subnet router early: advertising routes without a
    # routingInterface silently skips the UDP GRO throughput tuning.
    assertions = [
      {
        assertion = cfg.advertiseRoutes == [] || cfg.routingInterface != null;
        message = "mySystem.core.tailscale.advertiseRoutes is set but routingInterface is null; set the carrying NIC.";
      }
    ];

    environment.systemPackages = [pkgs.tailscale];
  };
}
