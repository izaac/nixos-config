{ config, pkgs, ... }:

{
  # 1. Container Virtualization (Podman for Distrobox)
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  
  hardware.nvidia-container-toolkit.enable = true;

  # 2. Performance & Environment Tweaks
  environment.sessionVariables = {
    EGL_PLATFORM = "wayland"; 
  };
}