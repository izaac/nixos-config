{pkgs, ...}: {
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
  ];
}
