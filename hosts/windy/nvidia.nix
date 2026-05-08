{
  config,
  pkgs,
  ...
}: {
  # Shared NVIDIA baseline (graphics, open module, VAAPI/VDPAU) lives in
  # modules/desktop/nvidia.nix. This file adds laptop-specific overrides.
  mySystem.desktop.nvidia.enable = true;

  # Add Intel QuickSync alongside the shared NVIDIA VAAPI stack.
  hardware.graphics.extraPackages = [pkgs.intel-media-driver];

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

  # Enable advanced tuning (Clock offsets / Fan control)
  services.xserver.deviceSection = ''
    Option "Coolbits" "28"
  '';

  environment.systemPackages = with pkgs; [
    nvtopPackages.full
  ];

  # Intel-specific env vars for better performance
  environment.sessionVariables = {
    VDPAU_DRIVER = "va_gl";
  };
}
