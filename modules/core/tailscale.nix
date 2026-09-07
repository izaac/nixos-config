{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.mySystem.core.tailscale;

  # Advertising a subnet and acting as an exit node both make this host forward
  # tailnet traffic onto the local network, so both need the same kernel
  # forwarding, reverse-path and NIC offload treatment.
  isRouter = cfg.advertiseRoutes != [] || cfg.advertiseExitNode;

  # --ssh enables Tailscale SSH (auth via tailnet ACLs, no extra ports).
  # The remaining flags carry an explicit value even when empty or false so
  # that clearing them in Nix actually withdraws them from the tailnet.
  upFlags = [
    "--ssh"
    "--accept-dns=${lib.boolToString cfg.acceptDns}"
    "--advertise-routes=${lib.concatStringsSep "," cfg.advertiseRoutes}"
    "--advertise-exit-node=${lib.boolToString cfg.advertiseExitNode}"
  ];
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

    advertiseExitNode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Offer this host to the tailnet as an exit node, so other devices can
        route all their internet traffic through it. Internally this advertises
        the default routes (0.0.0.0/0 and ::/0), and like subnet routes it must
        be approved once in the Tailscale admin console before clients can
        select it. Requires {option}`routingInterface` to be set.
      '';
    };

    acceptDns = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Let Tailscale manage this host's resolver, which is what enables
        MagicDNS. Off by default so Tailscale does not override the LAN DNS
        the workstations rely on; turn it on for hosts that need to resolve
        tailnet names.
      '';
    };

    routingInterface = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "eno1";
      description = ''
        Physical interface that carries routed traffic. When this host
        advertises routes or acts as an exit node, UDP GRO forwarding is
        enabled on it (Tailscale's recommended tuning for subnet-router/exit-node
        throughput). Null skips the tuning.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      # Opens the WireGuard UDP port (services.tailscale.port) in the firewall.
      openFirewall = true;
      # "server" enables IP forwarding sysctls so this node can route traffic
      # for the rest of the tailnet.
      useRoutingFeatures =
        if isRouter
        then "server"
        else "client";
      # extraUpFlags only reaches `tailscale up`, which the upstream module
      # runs solely on first authentication and only when authKeyFile is set.
      # Nothing here sets an auth key, so these flags never apply to an
      # already-enrolled node; extraSetFlags below is what actually converges
      # one. Kept in sync so an unattended first join lands in the same state.
      extraUpFlags = upFlags;
      # `tailscale set` runs on every activation, so every pref is stated
      # explicitly (including the negative cases) to overwrite any drift left
      # behind by a manual `tailscale set` on the host.
      extraSetFlags = upFlags;
    };

    # Subnet routing across the tailscale0 interface needs loose reverse-path
    # filtering, and the interface itself must be trusted by the firewall.
    networking.firewall = {
      checkReversePath = "loose";
      trustedInterfaces = ["tailscale0"];
    };

    # modules/core/performance.nix forces strict kernel rp_filter (=1) globally
    # for anti-spoof hardening. On a forwarding node that silently drops the
    # asymmetric tailnet<->LAN return paths this node is meant to carry, so
    # relax it to loose (=2) only when this host actually routes traffic.
    # Loose still rejects spoofed sources but permits valid asymmetric routing.
    # mkOverride 49 wins over the shared module's mkForce (priority 50).
    boot.kernel.sysctl = lib.mkIf isRouter {
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
    systemd.services.tailscale-udp-gro = lib.mkIf (isRouter && cfg.routingInterface != null) {
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

    # Catch a half-configured router early: forwarding traffic without a
    # routingInterface silently skips the UDP GRO throughput tuning.
    assertions = [
      {
        assertion = !isRouter || cfg.routingInterface != null;
        message = "mySystem.core.tailscale advertises routes or an exit node but routingInterface is null; set the carrying NIC.";
      }
    ];

    environment.systemPackages = [pkgs.tailscale];
  };
}
