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
# Desktop-responsiveness / gaming additions (all pure-nixpkgs, no patches):
#   - LRU_GEN + LRU_GEN_ENABLED: Multi-Gen LRU, enabled by default. Better page
#     reclaim under memory pressure — snappier with the 100% zstd zram swap.
#   - RCU_EXPERT: gates the RCU latency knobs below (not a behaviour change by
#     itself, just unhides RCU_BOOST / RCU_NOCB_CPU).
#   - RCU_BOOST + RCU_BOOST_DELAY=0: priority-boost preempted RCU readers
#     immediately, lowering tail latency under load. Valid because
#     PREEMPT_DYNAMIC selects PREEMPT_RCU and RT_MUTEXES is on.
#   - RCU_NOCB_CPU + RCU_NOCB_CPU_DEFAULT_ALL: offload RCU callback processing
#     to dedicated rcuop/rcuog kthreads on every CPU, removing RCU softirq
#     jitter from cores running game threads → smoother frametimes. Costs a
#     little call_rcu() overhead, negligible on this 16-core Zen 5 part.
#   - RCU_LAZY: batch lazy callbacks so the offloaded grace periods fire in
#     fewer, larger sweeps (fewer wakeups, lower power).
#
# Deliberately NOT done: -O3 builds and BORE/EEVDF scheduler tweaks are CachyOS
# *patches* absent from vanilla, and scx_lavd already replaces the in-kernel CPU
# scheduler at runtime — so out-of-tree scheduler patches would be redundant.
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

        # Desktop responsiveness: Multi-Gen LRU, on by default.
        LRU_GEN = yes;
        LRU_GEN_ENABLED = yes;

        # Latency: unlock + enable RCU priority boosting (boost immediately).
        RCU_EXPERT = yes;
        RCU_BOOST = yes;
        RCU_BOOST_DELAY = freeform "0";

        # Frametime smoothness: offload RCU callbacks off every CPU, batch them.
        RCU_NOCB_CPU = yes;
        RCU_NOCB_CPU_DEFAULT_ALL = yes;
        RCU_LAZY = yes;
      };
      ignoreConfigErrors = false; # fail loud if an option vanishes on a bump
    }
  ));

  # nixpkgs defaults to PREEMPT_LAZY; PREEMPT_DYNAMIC stays enabled upstream,
  # so full preemption is a boot flag (matches the old PREEMPT_DYNAMIC=full).
  boot.kernelParams = ["preempt=full"];
}
