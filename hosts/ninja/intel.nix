{pkgs, ...}: {
  # Intel Arc B580 (Xe2-HPG Battlemage) on ninja. The shared driver baseline
  # (modesetting, VA-API packages, LIBVA_DRIVER_NAME) lives in
  # modules/desktop/intel.nix; this file pins the host-specific xe stack
  # through the nixos-hardware common-gpu-intel option surface.
  mySystem.desktop.intel.enable = true;

  # Upstream xe kernel driver (Battlemage is not bound by i915), modern iHD
  # VAAPI stack, oneVPL media runtime, and Level-Zero compute runtime.
  # vaapiDriver steers away from the legacy intel-vaapi-driver/intel-ocl path.
  hardware.intelgpu = {
    driver = "xe";
    vaapiDriver = "intel-media-driver";
    computeRuntime = "default";
    mediaRuntime = "vpl-gpu-rt";
    loadInInitrd = true;
  };

  # iHD forces the VA-API backend; va_gl maps VDPAU onto VA-API.
  # ONEVPL_SEARCH_PATH lets oneVPL apps find libvpl on the OpenGL driver link.
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
    VDPAU_DRIVER = "va_gl";
    ONEVPL_SEARCH_PATH = "/run/opengl-driver/lib";
  };

  # Cap Intel Arc B580 board power to 160W (down from 200W VBIOS default) for sweet-spot efficiency
  systemd.services.arc-power-cap = {
    description = "Set Intel Arc B580 power cap to 160W";
    wantedBy = ["multi-user.target"];
    after = ["systemd-udev-settle.service"];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "arc-power-cap" ''
        for cap in /sys/class/drm/card*/device/hwmon/hwmon*/power1_cap; do
          if [ -f "$cap" ]; then
            echo 160000000 > "$cap"
          fi
        done
      '';
    };
  };
}
