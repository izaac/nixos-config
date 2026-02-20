{ ... }:

{
  # --- MEMORY MANAGEMENT (ZRAM) ---
  # Highly recommended for NVMe & high-core systems to prevent disk-thrashing
  zramSwap = {
    enable = true;
    algorithm = "zstd"; # Best balance of speed and compression
    memoryPercent = 100; # Use up to 100% of RAM as compressed swap (as previously configured)
    priority = 100; # High priority to ensure it's used before disk swap
  };

  # --- KERNEL TUNING ---
  boot.kernel.sysctl = {
    # ZRAM Swappiness (Aggressive swap-to-zram, avoids disk wait)
    "vm.swappiness" = 180;
    "vm.vfs_cache_pressure" = 50; # Keep filesystem cache longer (snappier Nautilus)
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;

    # Networking performance (lower latency)
    "net.core.default_qdisc" = "fq"; # Fair Queueing (Bufferbloat reduction)
    "net.ipv4.tcp_congestion_control" = "bbr"; # Google BBR congestion control
  };

  # Ananicy-cpp (Auto-nice daemon) - Disabled per Anticipation Strategy
  services.ananicy.enable = false;

  # Irqbalance - Disabled per Anticipation Strategy
  services.irqbalance.enable = false;
}
