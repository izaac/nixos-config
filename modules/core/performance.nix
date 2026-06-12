{
  config,
  lib,
  ...
}: let
  cfg = config.mySystem.core.performance;
in {
  options.mySystem.core.performance = {
    enable = lib.mkEnableOption "Core performance tweaks and kernel tuning";
  };

  config = lib.mkIf cfg.enable {
    # --- MEMORY MANAGEMENT (ZRAM) ---
    # Highly recommended for NVMe & high-core systems to prevent disk-thrashing
    zramSwap = {
      enable = true;
      algorithm = "zstd"; # Best balance of speed and compression
      memoryPercent = 100; # Use up to 100% of RAM as compressed swap (as previously configured)
      priority = 100; # High priority to ensure it's used before disk swap
    };

    # --- KERNEL TUNING ---
    boot = {
      kernel.sysctl = {
        # ZRAM Swappiness (Aggressive swap-to-zram, avoids disk wait)
        "vm.swappiness" = lib.mkDefault 180;
        "vm.vfs_cache_pressure" = 50; # Keep filesystem cache longer (snappier Nautilus)
        "vm.dirty_ratio" = 10;
        "vm.dirty_background_ratio" = 5;
        "vm.dirty_writeback_centisecs" = 500;
        "vm.dirty_expire_centisecs" = 1200;
        "vm.page_lock_unfairness" = 1;

        # Networking performance (lower latency)
        "net.core.default_qdisc" = "fq"; # Fair Queueing (Bufferbloat reduction)
        "net.ipv4.tcp_congestion_control" = "bbr"; # Google BBR congestion control

        # Kernel hardening (universal — safe on desktop and laptop).
        # mkForce because NixOS sets some of these at mkDefault priority and
        # equal priorities collide; we want the stricter values regardless.
        "kernel.kptr_restrict" = lib.mkForce 2; # Hide kernel pointers from non-root
        "kernel.kexec_load_disabled" = lib.mkForce 1; # Prevent hot-loading another kernel

        # Network security (universal). `all` and `default` must both be set:
        # - `all` is logical-OR'd with per-interface for receive paths and
        #   logical-AND'd for accept_redirects, but `send_redirects` is
        #   per-interface only — `all=0` does not propagate, so each interface
        #   inherits from `default` at creation time.
        # - Existing interfaces keep their initial value, so we mkForce both
        #   scopes to override NixOS defaults.
        "net.ipv4.conf.all.accept_redirects" = lib.mkForce 0;
        "net.ipv4.conf.default.accept_redirects" = lib.mkForce 0;
        "net.ipv4.conf.all.send_redirects" = lib.mkForce 0;
        "net.ipv4.conf.default.send_redirects" = lib.mkForce 0;
        "net.ipv4.conf.all.rp_filter" = lib.mkForce 1;
        "net.ipv4.conf.default.rp_filter" = lib.mkForce 1;
        "net.ipv4.conf.all.log_martians" = lib.mkForce 1;

        # IPv6 ICMP redirects — workstation has static routes (or RA-based
        # routes via `accept_ra`), so we never need to learn routes via
        # redirects. Closes a LAN-attacker MITM vector.
        "net.ipv6.conf.all.accept_redirects" = lib.mkForce 0;
        "net.ipv6.conf.default.accept_redirects" = lib.mkForce 0;
      };

      # --- GAMING & INPUT LATENCY ---
      kernelParams = [
        # Transparent Hugepages (THP) - 'madvise' allows apps (like Steam/Proton)
        # to opt-in, reducing TLB misses without the overhead of 'always'.
        "transparent_hugepage=madvise"

        # Disable USB autosuspend to eliminate tiny wake-up delays for mice/keyboards.
        "usbcore.autosuspend=-1"
      ];
    };

    # dbus-broker (Fedora/GNOME standard)
    # High-performance D-Bus message broker that reduces latency in desktop communication.
    services = {
      dbus.implementation = "broker";

      # Ananicy-cpp (Auto-nice daemon) - Disabled per Anticipation Strategy
      ananicy.enable = false;

      # Irqbalance - Spread interrupts across cores to reduce thermal hotspots
      irqbalance.enable = true;
    };
  };
}
