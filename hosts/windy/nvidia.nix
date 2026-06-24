{
  config,
  pkgs,
  ...
}: {
  # Shared NVIDIA baseline (graphics, open module, VAAPI/VDPAU) lives in
  # modules/desktop/nvidia.nix. This file adds laptop-specific overrides.
  mySystem.desktop.nvidia.enable = true;

  # Use the modern Intel media-driver VAAPI stack (Gen12+/QuickSync). This
  # also disables nixos-hardware's legacy Intel path, which would otherwise
  # pull in `intel-ocl` (SRB5.0) whose upstream source download is dead
  # (HTTP 403), breaking the build. intel-media-driver and
  # intel-compute-runtime are added automatically by the nixos-hardware
  # common-cpu-intel module.
  hardware.intelgpu.vaapiDriver = "intel-media-driver";

  hardware.nvidia = {
    powerManagement.enable = true; # Recommended for laptops to help with battery
    powerManagement.finegrained = true; # Better power savings for hybrid
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Prime / Hybrid Configuration
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  environment.systemPackages = with pkgs; [
    nvtopPackages.full
  ];
}
