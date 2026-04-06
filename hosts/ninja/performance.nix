{lib, ...}: {
  # Hardware-specific performance profile for ninja
  systemd.tmpfiles.rules = [
    "w /sys/bus/platform/drivers/amd_x3d_vcache/AMDI0101:00/amd_x3d_mode - - - - cache"
    "w /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference - - - - performance"
  ];

  boot.kernel.sysctl = {
    "kernel.split_lock_mitigate" = 0;

    "vm.swappiness" = 180;
    "vm.lr_gen_stats" = 0;
    "vm.lr_gen_active" = 0;
    "vm.page_lock_unfairness" = 1;

    "kernel.sched_autogroup_enabled" = 0;
    "kernel.sched_cfs_bandwidth_slice_us" = 3000;

    "vm.dirty_writeback_centisecs" = 1500;
    "vm.dirty_expire_centisecs" = 3000;

    "net.core.wmem_max" = 67108864;
    "net.core.rmem_max" = 67108864;
    "net.core.optmem_max" = 65536;
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.core.busy_poll" = 50;
    "net.core.busy_read" = 50;
    "net.core.netdev_max_backlog" = 16384;
    "net.core.netdev_budget" = 600;
    "net.core.netdev_budget_usecs" = 4000;
    "net.ipv4.tcp_max_syn_backlog" = 8192;
  };

  boot.tmp.useTmpfs = true;

  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
    extraArgs = ["--autopilot"];
  };

  systemd.targets.sleep.enable = true;
  systemd.targets.suspend.enable = true;
  systemd.targets.hibernate.enable = true;
  systemd.targets.hybrid-sleep.enable = true;
  services.logind.settings.Login = {
    HandleSuspendKey = "suspend";
    HandleHibernateKey = "hibernate";
    HandleLidSwitch = "ignore";
  };
  systemd.oomd.enable = true;

  services.flatpak.enable = true;
  services.fwupd.enable = false;
  services.acpid.enable = lib.mkForce false;

  nix.settings.max-jobs = 4;
  nix.settings.cores = 8;
  systemd.services.nix-daemon.serviceConfig = lib.mkForce {
    Nice = 19;
    CPUWeight = 1;
    IOWeight = 1;
    MemoryMax = "24G";
    MemoryHigh = "30G";
    AllowedCPUs = "8-15,24-31";
    CPUSchedulingPolicy = "idle";
    IOSchedulingClass = "idle";
    OOMScoreAdjust = 1000;
  };
}
