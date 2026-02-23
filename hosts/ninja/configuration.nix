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
      ../../modules/core/performance.nix
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
  programs.fuse.enable = true;

  # --- KERNEL & PERFORMANCE ---
  # Pin to Linux 6.18 to avoid NVIDIA build failures on latest (6.19)
  # boot.kernelPackages = pkgs.linuxPackages_6_18;
  # Switch to Zen Kernel (optimized for desktop/gaming latency)
  # Matches version 6.18 so it should remain compatible with NVIDIA drivers.
  boot.kernelPackages = pkgs.linuxPackages_zen;
  
  # --- HARDWARE OPTIMIZATIONS (Ryzen 9 9950X3D) ---
  # Modern way to set X3D Cache preference on boot.
  # This is safer and more reliable than postBootCommands.
  systemd.tmpfiles.rules = [ "w /sys/bus/platform/drivers/amd_x3d_vcache/AMDI0101:00/amd_x3d_mode - - - - cache" ];

  # --- EXPERIMENTAL FEATURES (REMOVED FOR STABILITY) ---
  # We are NOT enabling system.nixos-init, services.userborn, or system.etc.overlay
  # as these caused the login failure.

  # Enable systemd-based initrd
  boot.initrd.systemd.enable = true;
  
  # TCP BBR (Congestion Control) & System Latency Tweaks
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642; # Star Citizen / Hogwarts Legacy / Steam Deck parity
    "kernel.split_lock_mitigate" = 0; # Disable split lock mitigation for better gaming performance
    
    # Network Optimizations
    "net.core.wmem_max" = 67108864;    # 64 MiB - Optimized for high speed without bufferbloat
    "net.core.rmem_max" = 67108864;    # 64 MiB
    "net.ipv4.tcp_fastopen" = 3;      # Enable TCP Fast Open for better connection times
    "net.ipv4.tcp_slow_start_after_idle" = 0; # Keep TCP connection "hot"
    
    # MGLRU (Multi-Gen LRU) Optimizations
    # Helps with system responsiveness under high memory pressure.
    "vm.lr_gen_stats" = 1;
    "vm.lr_gen_active" = 1;

    # Network Throughput (Max Backlog for 2.5G+ NICs)
    "net.core.netdev_max_backlog" = 16384;
    "net.ipv4.tcp_max_syn_backlog" = 8192;
  };

  boot.tmp.useTmpfs = true;

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
  # Use 'performance' for better gaming stability, especially during intense combat.
  powerManagement.cpuFreqGovernor = "performance";

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
        "default.clock.allowed-rates" = [ 44100 48000 96000 ];
      };
      "context.modules" = [
        {
          name = "libpipewire-module-rt";
          args = {
            "nice.level" = -11;
            "rt.prio" = 88;
            "rt.time.soft" = 200000;
            "rt.time.hard" = 200000;
          };
          flags = [ "ifexists" "nofail" ];
        }
      ];
    };
    
    # Per-App Overrides (Stability Strategy)
    # Automatically apply large stable buffers to gaming applications
    extraConfig.pipewire-pulse."93-per-app-overrides" = {
      "pulse.rules" = [
        {
          matches = [ 
            { "application.process.binary" = "steam"; } 
            { "application.name" = "~.*wine.*"; } 
            { "application.name" = "~.*bottles.*"; } 
            { "application.name" = "~.*Elden Ring.*"; }
          ];
          actions = {
            update-props = {
              "pulse.min.quantum" = 2048;
              "pulse.max.quantum" = 8192;
              "pulse.idle.timeout" = 0;
            };
          } ;
        }
      ];
    };
  };

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
    vim
    wget
    curl
    file
    libglvnd
    tree
    pciutils
    usbutils
    parted
    sshfs
    fuse
    psmisc
    # pavucontrol # Graphical audio control (Removed per user request)
    zathura # TUI-like PDF viewer
    alsa-utils # CLI audio tools (aplay, amixer)
    libpulseaudio # Compatibility library
    gcr # Required for graphical prompts (GPG, etc.)
    pam_gnupg # Required for GPG unlocking
    
    # Archives
    zip
    xz
    unzip
    p7zip
    
    # Monitoring
    iotop
    iftop
    strace
    lsof
    lm_sensors
    ethtool
    dnsutils
  ];



  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  services.fstrim.enable = true;
  services.flatpak.enable = false;
  services.fwupd.enable = false;
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
