# CachyOS kernel for ninja (9950X3D).
#
# Uses linuxPackages_cachyos (GCC) from Chaotic-Nyx with ZEN4 override:
#   - BORE scheduler + CachyOS patchset
#   - GCC with -march=znver4 (Zen 4 microarch optimization)
#   - Requires local compile (~15-30min on 9950X3D)
#   - Compatible with nixpkgs nvidia (avoids LLVM cross-compile chain)
#
# Note: CachyOS kernels use their own config system (cachyOverride +
# prepare.nix) — standard nixpkgs boot.kernelPatches.structuredExtraConfig
# has no effect on these kernels.
{
  lib,
  pkgs,
  ...
}: {
  boot.kernelPackages = lib.mkForce (pkgs.linuxPackages_cachyos.cachyOverride {
    mArch = "ZEN4";
    ticksHz = 1000;
  });
}
