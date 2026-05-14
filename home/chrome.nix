{
  pkgs,
  inputs,
  ...
}: let
  nix-packages = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system};
  waylandFlags = [
    "--ozone-platform-hint=auto"
    "--enable-wayland-ime"
  ];
in {
  home.packages = [
    (pkgs.google-chrome.override {
      commandLineArgs = waylandFlags;
    })
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
    (nix-packages.brave-origin.override {
      commandLineArgs = waylandFlags;
    })
    (pkgs.microsoft-edge.override {
      commandLineArgs = waylandFlags;
    })
  ];
}
