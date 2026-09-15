{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.mySystem.core.virtualization;
in {
  options.mySystem.core.virtualization = {
    enable = lib.mkEnableOption "Podman and Distrobox container virtualization";
  };

  config = lib.mkIf cfg.enable {
    # 1. Container Virtualization (Podman)
    # Docker 29 defaults to the containerd-snapshotter ("overlayfs") storage
    # driver, which races distrobox's devpts setup and throws
    # "openat dev/ptmx: no such device" on first container creation. Podman is
    # distrobox's reference runtime and sidesteps that regression.
    virtualisation.podman = {
      enable = true;
      dockerSocket.enable = true;
      # Provide a `docker` CLI shim (symlink) so muscle-memory `docker ...`
      # commands resolve to Podman. The matching API socket is intentionally
      # the ROOTLESS user socket (configured in home/distrobox.nix), not the
      # rootful system socket: distrobox runs rootless, and a container escape
      # then lands as the unprivileged user instead of host root.
      dockerCompat = true;
      # Rootless containers need DNS resolution on the default network.
      defaultNetwork.settings.dns_enabled = true;
    };

    hardware.nvidia-container-toolkit.enable = lib.elem "nvidia" config.services.xserver.videoDrivers;

    # 2. Delegate all cgroup controllers to user sessions (containers, Gamescope, etc.)
    systemd.services."user@".serviceConfig.Delegate = "cpuset cpu io memory pids";

    # 3. Packages
    #
    # quickemu and quickgui built the first Windows guest and are gone: it is a
    # libvirt domain now, with no quickemu config left anywhere, and the pair
    # carried 2.3 GiB of closure. virt-viewer went with them, since virt-manager
    # embeds a SPICE viewer and spice-gtk provides spicy as a standalone one.
    #
    # remmina stays as the RDP client, which is the fallback route into a guest
    # whose display has gone dark. See docs/vfio-passthrough.md.
    environment.systemPackages = [pkgs.remmina];

    # 4. Performance & Environment Tweaks
    environment.sessionVariables = {
      EGL_PLATFORM = "wayland";
    };
  };
}
