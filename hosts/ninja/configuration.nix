{ config, pkgs, inputs, lib, userConfig, ... }:

{
  imports =
    [ 
      ./hardware.nix
      ./nvidia.nix
      ./network.nix
      ./udev-igc-fix.nix
      ../../modules/core
      ../../modules/core/sshfs.nix
      ../../modules/gaming
      ../../modules/desktop
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
  boot.kernelPackages = pkgs.linuxPackages_zen;
  
  # --- HARDWARE OPTIMIZATIONS (Ryzen 9 9950X3D) ---
  systemd.tmpfiles.rules = [ "w /sys/bus/platform/drivers/amd_x3d_vcache/AMDI0101:00/amd_x3d_mode - - - - cache" ];

  # Enable systemd-based initrd
  boot.initrd.systemd.enable = true;
  
  # TCP BBR (Congestion Control) & System Latency Tweaks
  boot.kernel.sysctl = {
    "kernel.split_lock_mitigate" = 0; 
    
    # Network Optimizations
    "net.core.wmem_max" = 67108864;    
    "net.core.rmem_max" = 67108864;    
    "net.ipv4.tcp_fastopen" = 3;      
    "net.ipv4.tcp_slow_start_after_idle" = 0; 
    
    # MGLRU (Multi-Gen LRU) Optimizations
    "vm.lr_gen_stats" = 1;
    "vm.lr_gen_active" = 1;

    # Network Throughput (Max Backlog for 2.5G+ NICs)
    "net.core.netdev_max_backlog" = 16384;
    "net.ipv4.tcp_max_syn_backlog" = 8192;
  };

  boot.tmp.useTmpfs = true;

  # --- KERNEL MODULES ---
  boot.blacklistedKernelModules = [
    "sp5100_tco" 
    "eeepc_wmi"  
    "joydev"     
    "pcspkr"     
  ];

  # --- CORE HARDWARE TWEAKS ---
  boot.kernelParams = [
    "boot.shell_on_fail"
    "pci=realloc,pcie_bus_safe" 
    "pcie_aspm=off"            
    "iommu=pt"                 
    "pcie_ports=native"        
    "usbcore.autosuspend=-1"   
    "amd_pstate=active"        
    "preempt=full"             
    "transparent_hugepage=madvise" 
  ];

  # CPU Power Management
  powerManagement.cpuFreqGovernor = "powersave";

  # --- DISABLE SUSPEND/HIBERNATE ---
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

  # Host-specific Audio Overrides
  services.pipewire = {
    wireplumber.extraConfig."95-alsa-soft-fixes" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            {
              "node.name" = "~alsa_input.usb-Blue_Microphones_Blue_Yeti.*";
            }
          ];
          actions = {
            update-props = {
              "session.suspend-on-idle" = false;
              "node.pause-on-idle" = false;
              "priority.driver" = 1050;
              "priority.session" = 1050;
              "audio.channels" = 2;
            };
          };
        }
        {
          matches = [
            {
              "node.name" = "~alsa_input.*";
            }
            {
              "node.name" = "~alsa_output.*";
            }
          ];
          actions = {
            update-props = {
              "session.suspend-on-idle" = false;
            };
          };
        }
      ];
    };
    
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

  # Hardware Firmware
  hardware.enableAllFirmware = true;

  # Optical Drive Support
  programs.k3b.enable = true;

  # System Packages (Essentials Only)
  environment.systemPackages = with pkgs; [
    libglvnd
    parted
    nmap
    alsa-utils # CLI audio tools (aplay, amixer)
    libpulseaudio # Compatibility library
  ];

  services.flatpak.enable = false;
  services.fwupd.enable = false;
  services.acpid.enable = lib.mkForce false;

  nix.settings.max-jobs = 16;
  nix.settings.cores = 8; 

  # Limit Nix Build Resources
  systemd.services.nix-daemon.serviceConfig = lib.mkForce {
    Nice = 19;
    CPUWeight = 1;
    IOWeight = 1;
    MemoryMax = "16G";
    MemoryHigh = "20G";
  };

  # --- DOCUMENTATION ---
  documentation = {
    enable = false;
    doc.enable = false;
    man.enable = false;
    info.enable = false;
  };

  system.stateVersion = "25.11";
}
