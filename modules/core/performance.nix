{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.mySystem.core.performance;
in {
  options.mySystem.core.performance = {
    enable = mkEnableOption "Core performance tweaks and kernel tuning";
  };

  config = mkIf cfg.enable {
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
        "vm.swappiness" = mkDefault 180;
        "vm.vfs_cache_pressure" = 50; # Keep filesystem cache longer (snappier Nautilus)
        "vm.dirty_ratio" = 10;
        "vm.dirty_background_ratio" = 5;

        # Networking performance (lower latency)
        "net.core.default_qdisc" = "fq"; # Fair Queueing (Bufferbloat reduction)
        "net.ipv4.tcp_congestion_control" = "bbr"; # Google BBR congestion control
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

      # Irqbalance - Disabled per Anticipation Strategy
      irqbalance.enable = false;
    };
  };
}
