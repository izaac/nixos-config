{ pkgs, ... }:

{
  # CachyOS Kernel (BORE, 1000Hz, Optimized for Gaming) - LTS Version
  # Using 6.12 LTS for better compatibility with xpadneo and other modules.
  # boot.kernelPackages = pkgs.linuxPackages_cachyos-lts;

  # Sched-ext (Dynamic Schedulers)
  # Using scx_rusty as it is generally more stable for desktop/gaming mixed workloads.
  # services.scx.enable = true;
  # services.scx.scheduler = "scx_rusty";
}
