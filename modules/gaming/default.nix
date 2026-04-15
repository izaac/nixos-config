{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.mySystem.gaming;
  nvidiaSmi = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi";
  gamemode-start = pkgs.writeShellScript "gamemode-start" ''
    # CPU: Push all cores to max performance EPP
    for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
      echo performance > "$f" 2>/dev/null
    done
    # CPU: Unlock full boost (5.7 GHz)
    for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
      echo 5756452 > "$f" 2>/dev/null
    done
    # GPU: Unlock full clock range for gaming
    ${nvidiaSmi} -lgc 210,2475
  '';
  gamemode-end = pkgs.writeShellScript "gamemode-end" ''
    # CPU: Restore cool-running EPP
    for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
      echo balance_performance > "$f" 2>/dev/null
    done
    # CPU: Restore summer-friendly frequency cap (4.5 GHz)
    for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
      echo 4500000 > "$f" 2>/dev/null
    done
    # GPU: Restore summer-friendly clock ceiling
    ${nvidiaSmi} -lgc 210,2100
  '';
in {
  options.mySystem.gaming = {
    enable = mkEnableOption "Gaming optimizations and tools";
  };

  config = mkIf cfg.enable {
    # 1. Controller & Hardware Support
    hardware = {
      steam-hardware.enable = true;
      xpadneo.enable = true; # Xbox Bluetooth
      uinput.enable = true; # Virtual Input (Critical for remapping tools)
    };

    # 2. Host Steam Configuration
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
      extraPackages = with pkgs; [
        libvdpau
        libva
        mangohud
        steamtinkerlaunch
        protonplus
        gamemode # The daemon and binaries
      ];
    };

    # 3. GameMode (Automatic Optimizations)
    programs.gamemode = {
      enable = true;
      enableRenice = true; # Allow gamemode to change process priority
      settings = {
        general = {
          softrealtime = "auto";
          renice = 5;
        };
        # Prevent "split_lock_mitigate" errors without needing root for every game
        custom = {
          start = "${pkgs.bash}/bin/bash -c 'sudo ${gamemode-start} && ${pkgs.libnotify}/bin/notify-send \"GameMode\" \"Performance Mode Active (5.7GHz + 2475MHz)\"'";
          end = "${pkgs.bash}/bin/bash -c 'sudo ${gamemode-end} && ${pkgs.libnotify}/bin/notify-send \"GameMode\" \"Efficiency Mode Restored (4.5GHz + 2100MHz)\"'";
        };
      };
    };

    # gamemode libraries already provided by programs.gamemode

    # Passwordless sudo-rs for GameMode thermal scripts
    security.sudo-rs.extraRules = [
      {
        groups = ["gamemode"];
        commands = [
          {
            command = toString gamemode-start;
            options = ["NOPASSWD"];
          }
          {
            command = toString gamemode-end;
            options = ["NOPASSWD"];
          }
        ];
      }
    ];

    # Boost memory map limits for modern titles like Cyberpunk or Hogwarts Legacy
    boot.kernel.sysctl."vm.max_map_count" = 2147483642;

    # 4. Sched-ext & Services
    services = {
      scx = {
        enable = true;
        scheduler = mkDefault "scx_lavd";
        extraArgs = mkDefault ["--autopilot"];
      };

      joycond.enable = false; # Nintendo Switch JoyCons (Merge L+R)
      input-remapper.enable = false;

      udev.packages = with pkgs; [
        game-devices-udev-rules # The big community list
        logitech-udev-rules
        openrgb # RGB Control access
      ];
    };

    # 6. Environment Tweaks
    environment.sessionVariables = {
      # G-Sync/VRR handled by host nvidia.nix

      # NVIDIA-specific DLSS/NGX
      PROTON_ENABLE_NGX_UPDATER = "1";

      # Fast Synchronization (ntsync in kernel 6.13+, fsync fallback)
      PROTON_ENABLE_NTSYNC = "1";
      WINE_FSYNC = "1";

      # NVIDIA & DX12 Performance Fixes
      # - no_upload_hvv: Fixes 'View Map Pressure' stutters in Cyberpunk 2077 and Elden Ring
      # - Shader Cache: Increased to 10GB to prevent re-compilation hitches
      VKD3D_CONFIG = "no_upload_hvv";
      __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
      __GL_SHADER_DISK_CACHE_SIZE = "10737418240";

      # Wayland Fixes for NVIDIA
      DISABLE_RT_CHECK = "1"; # Helps with some Raytracing titles on Wayland

      # Steam UI Stability
      # -no-cef-sandbox: Fixes web helper crashes on NixOS
      STEAM_EXTRA_ARGS = "-no-cef-sandbox";

      # Fix for X11 BadWindow errors on NVIDIA
      STEAM_DISABLE_PH_CLIPPED_VIDEO = "1";
    };
  };
}
