{lib, ...}: {
  # Hardware-specific performance profile for ninja
  systemd = {
    tmpfiles.rules = [
      "w /sys/bus/platform/drivers/amd_x3d_vcache/AMDI0101:00/amd_x3d_mode - - - - cache"
      "w /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference - - - - balance_performance"
      # Summer-friendly: cap boost at 4.5 GHz (4500000 KHz), GameMode unlocks full 5.7 GHz
      "w /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq - - - - 4500000"
    ];

    targets = {
      sleep.enable = true;
      suspend.enable = true;
      hibernate.enable = true;
      hybrid-sleep.enable = true;
    };

    oomd.enable = true;

    services.nix-daemon.serviceConfig = lib.mkForce {
      Nice = 19;
      CPUWeight = 1;
      IOWeight = 1;
      MemoryMax = "40G";
      MemoryHigh = "36G";
      AllowedCPUs = "8-15,24-31";
      CPUSchedulingPolicy = "idle";
      IOSchedulingClass = "idle";
      OOMScoreAdjust = 1000;
    };
  };

  boot = {
    # Universal hardening + dirty-page tuning live in modules/core/performance.nix.
    # Keys here are workstation-specific (high-core scheduling, big NIC buffers,
    # debug-friendly dmesg) and override mkDefault values from the shared module.
    kernel.sysctl = {
      "kernel.dmesg_restrict" = 0; # Workstation: allow non-root dmesg for debugging
      "kernel.split_lock_mitigate" = 0; # Performance trade-off on this 16-core CPU

      "net.core.wmem_max" = 67108864;
      "net.core.rmem_max" = 67108864;
      "net.core.optmem_max" = 65536;
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_slow_start_after_idle" = 0;
      "net.ipv4.tcp_tw_reuse" = 1;
      "net.core.netdev_max_backlog" = 5000;
      "net.core.netdev_budget" = 300;
      "net.core.netdev_budget_usecs" = 4000;
      "net.ipv4.tcp_max_syn_backlog" = 8192;
    };

    tmp.useTmpfs = true;
  };

  services = {
    # scx_lavd is configured in gaming/default.nix (mkDefault)

    logind.settings.Login = {
      HandleSuspendKey = "suspend";
      HandleHibernateKey = "hibernate";
      HandleLidSwitch = "ignore";
      NAutoVTs = 0; # Don't autospawn gettys — greetd handles login
    };

    flatpak.enable = true;
    fwupd.enable = false;
    acpid.enable = lib.mkForce false;
  };

  nix.settings = {
    max-jobs = 6;
    cores = 8;
  };
}
