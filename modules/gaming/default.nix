{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.mySystem.gaming;
  hasTuning = cfg.cpuBoostFreq != 0 && cfg.cpuBaseFreq != 0;
  hasGpuTuning = cfg.gpuBoostClock != 0 && cfg.gpuBaseClock != 0;
  hasNvidia = lib.elem "nvidia" config.services.xserver.videoDrivers;
  nvidiaSmi = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi";
  notify = "${pkgs.libnotify}/bin/notify-send";

  # Scripts only reference nvidia-smi when GPU tuning is configured
  gpuBoostCmd = optionalString (hasNvidia && hasGpuTuning) "${nvidiaSmi} -lgc 210,${toString cfg.gpuBoostClock}";
  gpuBaseCmd = optionalString (hasNvidia && hasGpuTuning) "${nvidiaSmi} -lgc 210,${toString cfg.gpuBaseClock}";

  thermal-guard = pkgs.writeShellScript "thermal-guard" ''
    # Thermal watchdog: throttle at ${toString cfg.thermalGuard.throttleTemp}°C, recover at ${toString cfg.thermalGuard.recoverTemp}°C
    # Find CPU temp sensor dynamically
    SENSOR=""
    for d in /sys/class/hwmon/hwmon*; do
      name=$(cat "$d/name" 2>/dev/null)
      case "$name" in
        k10temp|coretemp) SENSOR="$d/temp1_input"; break ;;
      esac
    done
    [ -z "$SENSOR" ] && exit 1
    rm -f /tmp/thermal-guard.stop

    THROTTLE=${toString (cfg.thermalGuard.throttleTemp * 1000)}
    RECOVER=${toString (cfg.thermalGuard.recoverTemp * 1000)}
    THROTTLED=0
    CALLER_UID="''${SUDO_UID:-1000}"

    while true; do
      temp=$(cat "$SENSOR" 2>/dev/null || echo 0)
      if [ "$THROTTLED" -eq 0 ] && [ "$temp" -gt "$THROTTLE" ]; then
        for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
          echo balance_performance > "$f" 2>/dev/null
        done
        ${optionalString hasTuning ''
      for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
        echo ${toString cfg.cpuBaseFreq} > "$f" 2>/dev/null
      done
    ''}
        ${optionalString (hasNvidia && hasGpuTuning) "${gpuBaseCmd} 2>/dev/null"}
        sudo -u "#$CALLER_UID" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$CALLER_UID/bus" \
          ${notify} -u critical -t 5000 "Thermal Guard" "''${temp%???}°C — clocks reduced"
        THROTTLED=1
        sleep 15
      elif [ "$THROTTLED" -eq 1 ] && [ "$temp" -lt "$RECOVER" ]; then
        for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
          echo performance > "$f" 2>/dev/null
        done
        ${optionalString hasTuning ''
      for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
        echo ${toString cfg.cpuBoostFreq} > "$f" 2>/dev/null
      done
    ''}
        ${optionalString (hasNvidia && hasGpuTuning) "${gpuBoostCmd} 2>/dev/null"}
        sudo -u "#$CALLER_UID" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$CALLER_UID/bus" \
          ${notify} -t 5000 "Thermal Guard" "''${temp%???}°C — clocks restored"
        THROTTLED=0
        sleep 15
      else
        sleep 5
      fi
      [ -f /tmp/thermal-guard.stop ] && rm -f /tmp/thermal-guard.stop && exit 0
    done
  '';

  gamemode-start = pkgs.writeShellScript "gamemode-start" ''
    for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
      echo performance > "$f" 2>/dev/null
    done
    ${optionalString hasTuning ''
      for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
        echo ${toString cfg.cpuBoostFreq} > "$f" 2>/dev/null
      done
    ''}
    ${optionalString (hasNvidia && hasGpuTuning) gpuBoostCmd}
  '';

  gamemode-end = pkgs.writeShellScript "gamemode-end" ''
    for f in /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference; do
      echo balance_performance > "$f" 2>/dev/null
    done
    ${optionalString hasTuning ''
      for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq; do
        echo ${toString cfg.cpuBaseFreq} > "$f" 2>/dev/null
      done
    ''}
    ${optionalString (hasNvidia && hasGpuTuning) gpuBaseCmd}
  '';

  boostDesc =
    (optionalString hasTuning "${toString (cfg.cpuBoostFreq / 1000)}MHz")
    + (optionalString (hasTuning && hasGpuTuning) " + ")
    + (optionalString hasGpuTuning "${toString cfg.gpuBoostClock}MHz GPU");
  baseDesc =
    (optionalString hasTuning "${toString (cfg.cpuBaseFreq / 1000)}MHz")
    + (optionalString (hasTuning && hasGpuTuning) " + ")
    + (optionalString hasGpuTuning "${toString cfg.gpuBaseClock}MHz GPU");
in {
  options.mySystem.gaming = {
    enable = mkEnableOption "Gaming optimizations and tools";

    cpuBoostFreq = mkOption {
      type = types.int;
      default = 0;
      description = "Max CPU frequency in KHz when GameMode is active (0 = no override)";
    };

    cpuBaseFreq = mkOption {
      type = types.int;
      default = 0;
      description = "Base CPU frequency in KHz when GameMode is inactive (0 = no override)";
    };

    gpuBoostClock = mkOption {
      type = types.int;
      default = 0;
      description = "Max GPU clock in MHz when GameMode is active (0 = no override, NVIDIA only)";
    };

    gpuBaseClock = mkOption {
      type = types.int;
      default = 0;
      description = "Base GPU clock in MHz when GameMode is inactive (0 = no override, NVIDIA only)";
    };

    thermalGuard = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable thermal watchdog during GameMode";
      };

      throttleTemp = mkOption {
        type = types.int;
        default = 90;
        description = "Temperature in °C to trigger throttle";
      };

      recoverTemp = mkOption {
        type = types.int;
        default = 80;
        description = "Temperature in °C to restore boost clocks";
      };
    };
  };

  config = mkIf cfg.enable {
    hardware = {
      steam-hardware.enable = true;
      xpadneo.enable = true;
      uinput.enable = true;
    };

    programs = {
      gamescope = {
        enable = true;
        capSysNice = true;
      };

      steam = {
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
          gamemode
        ];
      };

      gamemode = {
        enable = true;
        enableRenice = true;
        settings = {
          general = {
            softrealtime = "auto";
            renice = 5;
          };
          custom = mkIf (hasTuning || hasGpuTuning) {
            start = "${pkgs.bash}/bin/bash -c 'sudo ${gamemode-start}${optionalString cfg.thermalGuard.enable " && sudo ${thermal-guard} &"} && ${notify} \"GameMode\" \"Performance: ${boostDesc}\"'";
            end = "${pkgs.bash}/bin/bash -c '${optionalString cfg.thermalGuard.enable "touch /tmp/thermal-guard.stop; "}sudo ${gamemode-end} && ${notify} \"GameMode\" \"Efficiency: ${baseDesc}\"'";
          };
        };
      };
    };

    security.sudo-rs.extraRules = mkIf (hasTuning || hasGpuTuning) [
      {
        groups = ["gamemode"];
        commands =
          [
            {
              command = toString gamemode-start;
              options = ["NOPASSWD"];
            }
            {
              command = toString gamemode-end;
              options = ["NOPASSWD"];
            }
          ]
          ++ optional cfg.thermalGuard.enable {
            command = toString thermal-guard;
            options = ["NOPASSWD"];
          };
      }
    ];

    boot.kernel.sysctl."vm.max_map_count" = 2147483642;

    services = {
      scx = {
        enable = true;
        scheduler = mkDefault "scx_lavd";
        extraArgs = mkDefault ["--autopilot"];
      };
      joycond.enable = false;
      input-remapper.enable = false;
      udev.packages = with pkgs; [
        game-devices-udev-rules
        logitech-udev-rules
        openrgb
      ];
    };

    environment.sessionVariables =
      {
        PROTON_ENABLE_NTSYNC = "1";
        WINE_FSYNC = "1";
        VKD3D_CONFIG = "no_upload_hvv";
        __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
        __GL_SHADER_DISK_CACHE_SIZE = "10737418240";
        STEAM_EXTRA_ARGS = "-no-cef-sandbox";
        STEAM_DISABLE_PH_CLIPPED_VIDEO = "1";
      }
      // optionalAttrs hasNvidia {
        PROTON_ENABLE_NGX_UPDATER = "1";
        DISABLE_RT_CHECK = "1";
      };
  };
}
