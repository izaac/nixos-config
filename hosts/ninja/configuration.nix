{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./hardware.nix
    ./nvidia.nix
    ./network.nix
    ./udev-igc-fix.nix
    ../../modules/core
    ../../modules/gaming
    ../../modules/desktop
    ../../users/izaac
  ];

  # Custom Feature Flags
  mySystem.gaming.enable = true;
  mySystem.desktop.enable = true;
  mySystem.core.audio.enable = true;
  mySystem.core.bluetooth.enable = true;
  mySystem.core.codecs.enable = true;
  mySystem.core.virtualization.enable = true;
  mySystem.core.nfs.enable = false;
  mySystem.core.maintenance.enable = true;
  mySystem.core.performance.enable = true;
  mySystem.core.sops.enable = true;
  mySystem.core.sshfs.enable = true;
  mySystem.core.system.enable = true;
  mySystem.core.usb-fixes.enable = true;
  mySystem.core.user.enable = true;
  mySystem.core.home-manager.enable = true;
  mySystem.core.nix-ld.enable = true;

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.systemd-boot.editor = false;

  # File Systems
  boot.supportedFilesystems = ["exfat"];
  programs.fuse.enable = true;

  # --- KERNEL & PERFORMANCE ---
  # Switching to latest (6.19+) now that NVIDIA 595 beta provides compatibility
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # --- HARDWARE OPTIMIZATIONS (Ryzen 9 9950X3D) ---
  systemd.tmpfiles.rules = [
    "w /sys/bus/platform/drivers/amd_x3d_vcache/AMDI0101:00/amd_x3d_mode - - - - cache"
    # Set Energy Performance Preference to performance
    "w /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference - - - - performance"
  ];

  # Enable systemd-based initrd
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.tpm2.enable = false;

  # TCP BBR (Congestion Control) & System Latency Tweaks
  boot.kernel.sysctl = {
    "kernel.split_lock_mitigate" = 0;

    # Disk Writeback Tuning (Reduce wakeups)
    "vm.dirty_writeback_centisecs" = 1500;
    "vm.dirty_expire_centisecs" = 3000;

    # Network Optimizations
    "net.core.wmem_max" = 67108864;
    "net.core.rmem_max" = 67108864;
    "net.core.optmem_max" = 65536;
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_slow_start_after_idle" = 0;

    # Low Latency Network Polling
    "net.core.busy_poll" = 50;
    "net.core.busy_read" = 50;

    # MGLRU (Multi-Gen LRU) Optimizations
    "vm.lr_gen_stats" = 1;
    "vm.lr_gen_active" = 1;

    # Network Throughput (Max Backlog for 2.5G+ NICs)
    "net.core.netdev_max_backlog" = 16384;
    "net.core.netdev_budget" = 600;
    "net.core.netdev_budget_usecs" = 4000;
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
    "amd_pstate=active"
    "preempt=full"
  ];

  # --- SCHED-EXT (SCX) FOR 9950X3D GAMING ---
  services.scx = {
    enable = true;
    scheduler = "scx_lavd"; # Latency-aware scheduler for improved 1% lows and desktop snappiness
  };

  # --- ENABLE SUSPEND/HIBERNATE (NVIDIA 595+ STABLE) ---
  systemd.targets.sleep.enable = true;
  systemd.targets.suspend.enable = true;
  systemd.targets.hibernate.enable = true;
  systemd.targets.hybrid-sleep.enable = true;
  services.logind = {
    settings.Login = {
      HandleSuspendKey = "suspend";
      HandleHibernateKey = "hibernate";
      HandleLidSwitch = "ignore"; # Desktop: No lid
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
              "node.name" = "alsa_output.usb-Generic_USB_Audio-00.HiFi__Speaker__sink";
            }
          ];
          actions = {
            update-props = {
              "session.suspend-on-idle" = false;
              "node.pause-on-idle" = false;
              "audio.format" = "S32_LE";
              "audio.rate" = 48000;
              "api.alsa.period-size" = 1024;
              "api.alsa.headroom" = 1024;
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
        "default.clock.allowed-rates" = [44100 48000 96000];
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 1024;
        "default.clock.max-quantum" = 2048;
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
          flags = ["ifexists" "nofail"];
        }
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "node.description" = "Hifi EQ (Motherboard)";
            "media.name" = "Hifi EQ (Motherboard)";
            "filter.graph" = {
              nodes = [
                # --- LEFT CHANNEL ---
                {
                  type = "builtin";
                  name = "mix_l";
                  label = "mixer";
                  control = {"Gain 1" = 0.631;};
                } # -4.0 dB
                {
                  type = "builtin";
                  name = "eq1_l";
                  label = "bq_lowshelf";
                  control = {
                    "Freq" = 32.0;
                    "Q" = 1.0;
                    "Gain" = 8.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq2_l";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 64.0;
                    "Q" = 1.5;
                    "Gain" = 8.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq3_l";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 125.0;
                    "Q" = 1.5;
                    "Gain" = 2.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq3b_l";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 250.0;
                    "Q" = 1.5;
                    "Gain" = 3.0;
                  };
                } # Vocal Warmth
                {
                  type = "builtin";
                  name = "eq4_l";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 500.0;
                    "Q" = 1.5;
                    "Gain" = 0.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq5_l";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 1000.0;
                    "Q" = 1.5;
                    "Gain" = -3.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq6_l";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 2000.0;
                    "Q" = 1.5;
                    "Gain" = -4.0;
                  };
                } # Remove digital edge
                {
                  type = "builtin";
                  name = "eq7_l";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 4000.0;
                    "Q" = 1.5;
                    "Gain" = 0.0;
                  };
                } # Smoothness
                {
                  type = "builtin";
                  name = "eq8_l";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 8000.0;
                    "Q" = 1.5;
                    "Gain" = 3.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq9_l";
                  label = "bq_highshelf";
                  control = {
                    "Freq" = 16000.0;
                    "Q" = 1.0;
                    "Gain" = 2.0;
                  };
                }
                # --- RIGHT CHANNEL ---
                {
                  type = "builtin";
                  name = "mix_r";
                  label = "mixer";
                  control = {"Gain 1" = 0.631;};
                }
                {
                  type = "builtin";
                  name = "eq1_r";
                  label = "bq_lowshelf";
                  control = {
                    "Freq" = 32.0;
                    "Q" = 1.0;
                    "Gain" = 8.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq2_r";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 64.0;
                    "Q" = 1.5;
                    "Gain" = 8.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq3_r";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 125.0;
                    "Q" = 1.5;
                    "Gain" = 2.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq3b_r";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 250.0;
                    "Q" = 1.5;
                    "Gain" = 3.0;
                  };
                } # Vocal Warmth
                {
                  type = "builtin";
                  name = "eq4_r";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 500.0;
                    "Q" = 1.5;
                    "Gain" = 0.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq5_r";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 1000.0;
                    "Q" = 1.5;
                    "Gain" = -3.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq6_r";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 2000.0;
                    "Q" = 1.5;
                    "Gain" = -4.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq7_r";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 4000.0;
                    "Q" = 1.5;
                    "Gain" = 0.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq8_r";
                  label = "bq_peaking";
                  control = {
                    "Freq" = 8000.0;
                    "Q" = 1.5;
                    "Gain" = 3.0;
                  };
                }
                {
                  type = "builtin";
                  name = "eq9_r";
                  label = "bq_highshelf";
                  control = {
                    "Freq" = 16000.0;
                    "Q" = 1.0;
                    "Gain" = 2.0;
                  };
                }
              ];
              links = [
                {
                  output = "mix_l:Out";
                  input = "eq1_l:In";
                }
                {
                  output = "eq1_l:Out";
                  input = "eq2_l:In";
                }
                {
                  output = "eq2_l:Out";
                  input = "eq3_l:In";
                }
                {
                  output = "eq3_l:Out";
                  input = "eq3b_l:In";
                }
                {
                  output = "eq3b_l:Out";
                  input = "eq4_l:In";
                }
                {
                  output = "eq4_l:Out";
                  input = "eq5_l:In";
                }
                {
                  output = "eq5_l:Out";
                  input = "eq6_l:In";
                }
                {
                  output = "eq6_l:Out";
                  input = "eq7_l:In";
                }
                {
                  output = "eq7_l:Out";
                  input = "eq8_l:In";
                }
                {
                  output = "eq8_l:Out";
                  input = "eq9_l:In";
                }
                {
                  output = "mix_r:Out";
                  input = "eq1_r:In";
                }
                {
                  output = "eq1_r:Out";
                  input = "eq2_r:In";
                }
                {
                  output = "eq2_r:Out";
                  input = "eq3_r:In";
                }
                {
                  output = "eq3_r:Out";
                  input = "eq3b_r:In";
                }
                {
                  output = "eq3b_r:Out";
                  input = "eq4_r:In";
                }
                {
                  output = "eq4_r:Out";
                  input = "eq5_r:In";
                }
                {
                  output = "eq5_r:Out";
                  input = "eq6_r:In";
                }
                {
                  output = "eq6_r:Out";
                  input = "eq7_r:In";
                }
                {
                  output = "eq7_r:Out";
                  input = "eq8_r:In";
                }
                {
                  output = "eq8_r:Out";
                  input = "eq9_r:In";
                }
              ];
              inputs = ["mix_l:In 1" "mix_r:In 1"];
              outputs = ["eq9_l:Out" "eq9_r:Out"];
            };
            "capture.props" = {
              "node.name" = "hifi_eq_input";
              "media.class" = "Audio/Sink";
              "audio.channels" = 2;
              "audio.position" = ["FL" "FR"];
            };
            "playback.props" = {
              "node.name" = "hifi_eq_output";
              "node.passive" = true;
              "audio.channels" = 2;
              "audio.position" = ["FL" "FR"];
              "node.target" = "alsa_output.usb-Generic_USB_Audio-00.HiFi__Speaker__sink";
            };
          };
        }
      ];
      "context.rules" = [
        {
          matches = [
            {"application.name" = "ELDEN RING™";}
            {"application.name" = "cava";}
          ];
          actions = {
            update-properties = {
              "node.latency" = "1024/48000";
            };
          };
        }
      ];
    };

    # Per-App Overrides (Stability Strategy)
    extraConfig.pipewire-pulse."93-per-app-overrides" = {
      "pulse.rules" = [
        {
          matches = [
            {"application.process.binary" = "steam";}
            {"application.name" = "~.*wine.*";}
            {"application.name" = "~.*bottles.*";}
            {"application.name" = "~.*Elden Ring.*";}
          ];
          actions = {
            update-props = {
              "pulse.min.quantum" = 1024;
              "pulse.max.quantum" = 4096;
              "pulse.idle.timeout" = 0;
            };
          };
        }
      ];
    };
  };

  # Hardware Firmware
  hardware.enableAllFirmware = true;

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

  nix.settings.max-jobs = 4;
  nix.settings.cores = 8;

  # Limit Nix Build Resources
  systemd.services.nix-daemon.serviceConfig = lib.mkForce {
    Nice = 19;
    CPUWeight = 1;
    IOWeight = 1;
    MemoryMax = "24G";
    MemoryHigh = "30G";
    # Isolation: Keep builds on CCD1 (cores 8-15 and their SMT siblings 24-31)
    AllowedCPUs = "8-15,24-31";
    # Latency: Use IDLE scheduling for CPU and IO
    CPUSchedulingPolicy = "idle";
    IOSchedulingClass = "idle";
    # Safety: Ensure nix-daemon is killed before the desktop if OOM occurs
    OOMScoreAdjust = 1000;
  };

  # --- SYSTEM-WIDE FIREFOX POLICIES ---
  # Ensures policies apply even to custom VIP wrappers
  programs.firefox = {
    enable = true;
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = false;
        Cryptomining = true;
        Fingerprinting = true;
      };
      DisablePocket = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      DontCheckDefaultBrowser = true;
      DisplayBookmarksToolbar = "never";
      DisplayMenuBar = "default-off";
      SearchBar = "unified";
      HardwareAcceleration = true;
      Preferences = {
        "privacy.resistFingerprinting" = false;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "dom.security.https_only_mode" = true;
        "browser.contentblocking.category" = "strict";
        "browser.ping-centre.telemetry" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.server" = "data:,";
        "toolkit.telemetry.archive.enabled" = false;
        "app.normandy.enabled" = false;
        "app.normandy.api_url" = "";
        "browser.discovery.enabled" = false;
        "browser.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionPolicyAccepted" = false;
        "datareporting.policy.dataSubmissionPolicyBypassNotification" = true;
        "beacon.enabled" = false;
        "network.http.max-connections" = 1800;
        "network.http.max-persistent-connections-per-server" = 10;
        "network.trr.mode" = 5;
        "network.captive-portal-service.enabled" = false;
        "browser.cache.disk.enable" = false;
        "browser.cache.memory.capacity" = 1048576;
        "browser.sessionstore.interval" = 600000;
        "ui.systemUsesDarkTheme" = 1;

        # --- HIGH QUALITY AUDIO & STREAMING ---
        "media.resampling.enabled" = false; # Avoid browser-level downsampling
        "media.audio_max_channels" = 8; # Support up to 7.1 surround sound
        "media.mediasource.webm.enabled" = true; # High quality YT Music audio (Opus)
        "media.mediasource.webm.audio.enabled" = true; # Force WebM for audio-only
        "media.webm.enabled" = true; # Ensure WebM is globally enabled
        "media.opus.enabled" = true; # Ensure Opus is globally enabled
        "media.setsinkid.enabled" = true; # Allow manual output device selection
        "media.track.enabled" = true; # Enable multi-track audio selection
        "media.getusermedia.audio.processing.agc.enabled" = false; # Disable Auto-Gain (flattens music)
        "media.getusermedia.audio.processing.noise_suppression" = false; # Disable noise filtering for high-fidelity

        # --- GPU HARDWARE ACCELERATION ---
        "media.ffmpeg.vaapi.enabled" = true; # Enable Hardware Video Decoding
        "media.rdd-ffmpeg.enabled" = false; # Disable RDD sandbox for NVIDIA VA-API
        "gfx.webrender.all" = true; # Force GPU Page Rendering
        "widget.dmabuf.force-enabled" = true; # Zero-copy buffer sharing for Wayland
      };
    };
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
