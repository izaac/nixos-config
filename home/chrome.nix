{
  pkgs,
  inputs,
  ...
}: let
  nix-packages = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system};
in {
  # Chromium-family browsers run native Wayland via NIXOS_OZONE_WL=1
  # (home/shell/env.nix); no per-package flags needed.
  home.packages = [
    pkgs.google-chrome
    (pkgs.ungoogled-chromium.override {
      commandLineArgs = [
        # GPU / hardware-accelerated rendering
        "--ignore-gpu-blocklist"
        "--enable-zero-copy"
        "--enable-gpu-rasterization"
        "--canvas-oop-rasterization"
        "--enable-features=VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,VaapiVideoDecoder,UseMultiPlaneFormatForHardwareVideo,AcceleratedVideoEncoder"
        # Native Wayland
        "--ozone-platform=wayland"
        "--enable-wayland-ime"
      ];
    })
    nix-packages.brave-origin
    pkgs.microsoft-edge
  ];
}
