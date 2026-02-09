{ config, pkgs, inputs, lib, userConfig, ... }:

{
  imports =
    [ 
      ./hardware.nix
      ./nvidia.nix
      ./network.nix
      ../../modules/core/nix-ld.nix
      ../../modules/core/codecs.nix
      ../../modules/core/bluetooth-audio.nix
      ../../modules/core/virtualization.nix
      ../../modules/core/usb-fixes.nix
      ../../modules/core/maintenance.nix
      ../../modules/core/sshfs.nix
      ../../modules/gaming/default.nix
      ../../modules/desktop/default.nix
    ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.systemd-boot.editor = false;

  # File Systems
  boot.supportedFilesystems = [ "exfat" ];

  # --- KERNEL & PERFORMANCE ---
  # Switch to Unstable Mainline Kernel for latest scheduler/driver updates (Ryzen 9000/RTX 5000)
  boot.kernelPackages = pkgs.unstable.linuxPackages_latest;
  
  # TCP BBR (Congestion Control) & System Latency Tweaks
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642; # Star Citizen / Hogwarts Legacy / Steam Deck parity
    
    # Network Optimizations
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "fq";
    "net.core.wmem_max" = 67108864;    # 64 MiB - Optimized for high speed without bufferbloat
    "net.core.rmem_max" = 67108864;    # 64 MiB
    "net.ipv4.tcp_fastopen" = 3;      # Enable TCP Fast Open for better connection times
    "net.ipv4.tcp_slow_start_after_idle" = 0; # Keep TCP connection "hot"
    
    # Virtual Memory & Latency
    "vm.swappiness" = 180;            # Aggressively use ZRAM
    "vm.watermark_boost_factor" = 0;  # Reduce latency spikes
    "vm.vfs_cache_pressure" = 50;     # Keep inode/dentry caches longer
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
    "vm.compaction_proactiveness" = 0; # Reduce background jitter

    # MGLRU (Multi-Gen LRU) Optimizations
    # Helps with system responsiveness under high memory pressure.
    "vm.lr_gen_stats" = 1;
    "vm.lr_gen_active" = 1;

    # Network Throughput (Max Backlog for 2.5G+ NICs)
    "net.core.netdev_max_backlog" = 16384;
    "net.ipv4.tcp_max_syn_backlog" = 8192;
  };

  # ZRAM (Compressed RAM Swap)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
  };
  boot.tmp.useTmpfs = true;

  # Irqbalance for better interrupt distribution across cores
  services.irqbalance.enable = true;

  # --- KERNEL MODULES ---
  boot.blacklistedKernelModules = [
    "sp5100_tco" # AMD Watchdog (can cause freezes)
    "eeepc_wmi"  # Legacy ASUS laptop driver
    "joydev"     # Legacy joystick API
    "pcspkr"     # Motherboard beep
  ];

  # --- CORE HARDWARE TWEAKS ---
  boot.kernelParams = [
    "boot.shell_on_fail"
    "split_lock_detect=off"    # Improves Elden Ring latency / removes bus lock warning
    "pci=realloc,pcie_bus_safe" # Resolves the 'can't claim bridge window' conflict in logs & ensures MPS stability
    "pcie_aspm=off"            # Disables Active State Power Management
    "iommu=pt"                 # Reduces NVMe/CPU latency
    "pcie_ports=native"        # Fixes ASUS 'bridge window' conflicts
    "usbcore.autosuspend=-1"   # Fixes Bluetooth/USB device disconnects
    "amd_pstate=active"        # Enables the modern AMD P-State driver for Ryzen 9 9950X3D
    "preempt=full"             # Request full preemption for lower latency
    "transparent_hugepage=madvise" # Latency-friendly THP
  ];

  # CPU Power Management
  # "powersave" governor with amd_pstate=active intelligently scales clocks based on load for efficiency.
  powerManagement.cpuFreqGovernor = "powersave";

  # --- DISABLE SUSPEND/HIBERNATE ---
  # Prevent accidental suspend which causes black screen freezes
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
  services.logind = {
    settings.Login = {
      HandleSuspendKey = "ignore";
      HandleHibernateKey = "ignore";
      HandleLidSwitch = "ignore";
    };
  };

  # Enable systemd-oomd for better memory pressure management
  systemd.oomd.enable = true;

  time.timeZone = "America/Phoenix";
  i18n.defaultLocale = "en_US.UTF-8";

  # Audio (Pipewire)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    
    # High Fidelity & Stability Configuration
    extraConfig.pipewire."92-high-quality" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 32000 24000 16000 ];
        "default.clock.quantum" = 512;
        "default.clock.min-quantum" = 32;
        "default.clock.max-quantum" = 1024;
      };
    };
  };

  # Disable audio power saving & optimized USB audio for DJI/Razer/Pro devices
  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=0
    options snd_usb_audio skip_validation=1 ignore_ctl_error=1 device_setup=1
  '';

  # User Account
    users.users.${userConfig.username} = {
      isNormalUser = true;
      description = userConfig.name;
      extraGroups = [ "wheel" "input" "video" "render" "dialout" "podman" "audio" ];
    };

  # Sudo Config
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
    extraConfig = ''
      Defaults editor=${pkgs.vim}/bin/vim
    '';
  };

  # Hardware Firmware
  hardware.enableAllFirmware = true;

  # Optical Drive Support
  programs.k3b.enable = true;

  # System Packages (Essentials Only)
  environment.systemPackages = with pkgs; [
    small.vim
    small.wget
    small.curl
    small.file
    libglvnd
    small.tree
    small.pciutils
    small.usbutils
    small.parted
    small.sshfs
    small.psmisc
    # small.pavucontrol # Graphical audio control (Removed per user request)
    zathura # TUI-like PDF viewer
    small.alsa-utils # CLI audio tools (aplay, amixer)
    libpulseaudio # Compatibility library
    gcr # Required for graphical prompts (GPG, etc.)
    pam_gnupg # Required for GPG unlocking
  ];

  security.pam.services.login.gnupg.enable = true;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  services.fstrim.enable = true;
  services.flatpak.enable = false;
  services.power-profiles-daemon.enable = false;
  services.acpid.enable = lib.mkForce false;

  # Nix Maintenance
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nix.settings.max-jobs = 16;
  nix.settings.cores = 8; # Limit each job to 8 cores to leave room for the system
  nix.settings.auto-optimise-store = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "@wheel" ];

  # Lower nix-daemon priority
  nix.daemonCPUSchedPolicy = "idle";
  nix.daemonIOSchedClass = "idle";

  nixpkgs.config.permittedInsecurePackages = [
    "ventoy-qt5-1.1.07"
  ];

  # Limit Nix Build Resources
  systemd.services.nix-daemon.serviceConfig = lib.mkForce {
    Nice = 19;
    CPUWeight = 1;
    IOWeight = 1;
    MemoryMax = "16G";
    MemoryHigh = "20G";
  };

  # --- DOCUMENTATION ---
  # Disable documentation to save space and reduce small file overhead.
  documentation = {
    enable = false;
    doc.enable = false;
    man.enable = false;
    info.enable = false;
  };

  system.stateVersion = "25.11";
}
