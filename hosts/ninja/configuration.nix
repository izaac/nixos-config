{ config, pkgs, inputs, userConfig, ... }:

{
  imports =
    [ 
      ./hardware.nix
      ./nvidia.nix
      ./network.nix
      ../../modules/core/nix-ld.nix
      ../../modules/core/codecs.nix
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
  boot.loader.systemd-boot.configurationLimit = 5;
  boot.loader.systemd-boot.editor = false;

  # --- KERNEL & PERFORMANCE ---
  boot.kernelPackages = pkgs.linuxPackages_latest;
  
  # TCP BBR (Congestion Control) & System Latency Tweaks
  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642; # Star Citizen / Hogwarts Legacy / Steam Deck parity
    
    # Network Optimizations
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "fq";
    "net.core.wmem_max" = 1073741824; # 1 GiB
    "net.core.rmem_max" = 1073741824; # 1 GiB
    "net.ipv4.tcp_fastopen" = 3;      # Enable TCP Fast Open for better connection times
    
    # Virtual Memory & Latency
    "vm.swappiness" = 10;             # Only swap if absolutely necessary
    "vm.vfs_cache_pressure" = 50;     # Keep inode/dentry caches longer
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;
    "vm.compaction_proactiveness" = 0; # Reduce background jitter
  };

  # ZRAM (Compressed RAM Swap)
  zramSwap.enable = true;

  # --- CORE HARDWARE TWEAKS ---
  boot.kernelParams = [
    "boot.shell_on_fail"
    "split_lock_detect=off"    # Improves Elden Ring latency / removes bus lock warning
    "pci=realloc"              # Resolves the 'can't claim bridge window' conflict in logs
    "pcie_aspm=off"            # Fixes the 'retraining failed' PCIe error
    "iommu=pt"                 # Reduces NVMe/CPU latency
    "pcie_ports=native"        # Fixes ASUS 'bridge window' conflicts
    "usbcore.autosuspend=-1"   # Fixes Bluetooth/USB device disconnects
    "amd_pstate=active"        # Enables the modern AMD P-State driver for Ryzen 9 9950X3D
    "preempt=full"             # Request full preemption for lower latency
    "transparent_hugepage=madvise" # Latency-friendly THP
  ];

  # CPU Power Management
  # "powersave" governor with amd_pstate=active intelligently scales clocks based on load.
  # It does NOT mean "slow", it means "efficient".
  powerManagement.cpuFreqGovernor = "powersave";

  # Bluetooth Optimizations
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source,Sink,Media,Socket";
        Experimental = true; # Enables battery reporting for some devices
      };
    };
  };

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
  };

  # User Account
  users.users.${userConfig.username} = {
    isNormalUser = true;
    description = userConfig.name;
    extraGroups = [ "networkmanager" "wheel" "docker" "input" "video" "libvirtd" "kvm" "render" "dialout" ];
  };

  # Sudo Config
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
    extraConfig = ''
      Defaults editor=${pkgs.vim}/bin/vim
    '';
  };

  # System Packages (Essentials Only)
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    file
    libglvnd
    tree
    pciutils
    parted
    sshfs
  ];

  # Services
  services.openssh = {
    enable = true;
    settings = {
      # Hardcore mode: No passwords, keys only.
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  services.fstrim.enable = true;
  services.flatpak.enable = true;

  # Nix Maintenance
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nix.settings.auto-optimise-store = false;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.11";
}
