{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.mySystem.core.virtualization;
in {
  options.mySystem.core.virtualization = {
    enable = mkEnableOption "Docker and Distrobox virtualization";
  };

  config = mkIf cfg.enable {
    # 1. Container Virtualization (Docker)
    virtualisation.docker = {
      enable = true;
    };

    hardware.nvidia-container-toolkit.enable = lib.elem "nvidia" config.services.xserver.videoDrivers;

    # 2. Delegate all cgroup controllers to user sessions (containers, Gamescope, etc.)
    systemd.services."user@".serviceConfig.Delegate = "cpuset cpu io memory pids";

    # 3. Performance & Environment Tweaks
    environment.sessionVariables = {
      EGL_PLATFORM = "wayland";
    };
  };
}
