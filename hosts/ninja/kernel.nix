# Nixpkgs kernel for ninja (9950X3D, Zen 5).
#
# Replaces linuxPackages_cachyos (Chaotic-Nyx) with a pure-nixpkgs kernel —
# removes the chaotic flake input entirely (supply-chain reduction). The
# custom config means no Hydra cache hit: the kernel always compiles locally
# (~20-35 min on this machine; the NVIDIA open module adds a few minutes).
#
#   - X86_NATIVE_CPU (upstream since 6.16): -march=native, which resolves to
#     znver5 on this machine (better than the old mArch = "ZEN4").
#     IMPORTANT: gcc reads the *builder's* CPUID — always build this host's
#     kernel on ninja itself. Never offload to the Mac linux-builder or any
#     non-Zen-5 remote builder ("just test-host ninja" from the Mac would
#     produce a wrongly-marched kernel).
#   - HZ=1000 matches the old cachyOverride ticksHz = 1000.
#   - CONFIG_SCHED_CLASS_EXT is already enabled by nixpkgs (kernels >= 6.12),
#     so scx_lavd keeps working with no extra config.
#   - NTSYNC built as a module for Wine/Proton parity with the CachyOS kernel.
#   - hardware.nvidia.package follows boot.kernelPackages, so the NVIDIA open
#     module rebuilds against this kernel automatically.
#
# Note: boot.kernelPatches.extraStructuredConfig was removed from nixpkgs —
# kernel.override { structuredExtraConfig = ...; } is the supported way.
{
  lib,
  pkgs,
  ...
}: {
  boot.kernelPackages = lib.mkForce (pkgs.linuxPackagesFor (
    pkgs.linux_latest.override {
      structuredExtraConfig = with lib.kernel; {
        X86_NATIVE_CPU = yes; # -march=native (+ -Ctarget-cpu=native for Rust)
        HZ = freeform "1000";
        HZ_1000 = yes; # 1000Hz tick
        NTSYNC = module; # NT sync primitives (Wine/Proton)
      };
      ignoreConfigErrors = false; # fail loud if an option vanishes on a bump
    }
  ));

  # nixpkgs defaults to PREEMPT_LAZY; PREEMPT_DYNAMIC stays enabled upstream,
  # so full preemption is a boot flag (matches the old PREEMPT_DYNAMIC=full).
  boot.kernelParams = ["preempt=full"];
}
