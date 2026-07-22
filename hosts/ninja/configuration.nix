{
  pkgs,
  lib,
  inputs,
  siteConfig,
  ...
}: {
  # --- VIRTUALIZATION VARIANT ---
  virtualisation.vmVariant = {
    # Disable NVIDIA in the VM
    services.xserver.videoDrivers = lib.mkForce ["modesetting"];
    hardware = {
      nvidia.package = lib.mkForce pkgs.hello;
      graphics.extraPackages = lib.mkForce [];
      # Disable NVIDIA toolkit in VM
      nvidia-container-toolkit.enable = lib.mkForce false;
    };
    systemd.services.nvidia-lock-clocks.enable = lib.mkForce false;
    # No sops secrets needed in the VM
    sops.gnupg.home = lib.mkForce "/tmp/gnupg";
  };

  # This is 'ninja' — a high-performance workstation built around the Ryzen 9 9950X3D and NVIDIA.
  # It's optimized for zero-latency desktop feel, high-fidelity audio, and maximum gaming throughput.

  imports = [
    ./hardware.nix
    ./disko.nix
    ./nvidia.nix
    ./network.nix
    ./udev-igc-fix.nix
    ./boot.nix
    ./kernel.nix
    ./performance.nix
    ./audio.nix
    ./chromium.nix
    ./plex.nix
    ./ssh.nix
    ../../modules/core
    ../../modules/gaming
    ../../modules/desktop
    ../../modules/profiles/workstation.nix
    ../../users/izaac
    # nixos-hardware: AMD pstate, NVIDIA (nonprime/desktop), SSD trim
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia-nonprime
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  # --- HOST DELTAS ---
  # The shared baseline lives in modules/profiles/workstation.nix; only
  # ninja-specific settings remain here.
  mySystem = {
    gaming = {
      # GameStream host for the Mac's Moonlight client — ninja only; the
      # laptop is a thin client and gets no CUDA build or open firewall.
      sunshine.enable = true;
      cpuBoostFreq = 5756452; # 5.7 GHz
      cpuBaseFreq = 4500000; # 4.5 GHz
      gpuBoostClock = 2475; # RTX 5070 Ti gaming
      gpuBaseClock = 2100; # RTX 5070 Ti efficiency
      thermalGuard = {
        enable = true;
        throttleTemp = 90;
        recoverTemp = 80;
      };
    };
    core.tailscale = {
      enable = true;
      advertiseRoutes = [siteConfig.subnet];
      routingInterface = "eno1";
    };
  };

  # --- TOOLS OF THE TRADE ---
  # Essential CLI utilities for system management and audio debugging.
  environment.systemPackages = with pkgs; [
    libglvnd
    parted
    nmap
    alsa-utils # CLI audio tools (aplay, amixer)
    libpulseaudio # Compatibility library
    ddcutil # Monitor brightness control via DDC/CI
    sbctl # Secure Boot key management (Limine signing/enroll)
    # btop lives in modules/core/maintenance.nix (TTY rescue baseline)

    # Rust uutils coreutils, PATH-level only. hiPrio shadows the GNU
    # coreutils-full symlinks in /run/current-system/sw/bin for the binaries
    # uutils ships (ls, cp, mv, cat, ...). Tools uutils lacks (e.g. stdbuf)
    # still resolve to GNU at normal priority — best of both.
    #
    # Scope is deliberately PATH-only: every nixpkgs package pins its own GNU
    # coreutils by store path at build time, so this does NOT touch the canoe /
    # canoe-niri live ISOs, the installer, nixos-rebuild, nh, docker, etc.
    (lib.hiPrio uutils-coreutils-noprefix)
  ];

  # Allow ddcutil to access I2C devices
  hardware.i2c.enable = true;

  # --- SLIMMING THE SYSTEM ---
  # Keep man pages for offline reference; skip NixOS module docs and info pages.
  documentation = {
    enable = true;
    doc.enable = false;
    man.enable = true;
    info.enable = false;
  };

  # MIME defaults centralized in home/desktop.nix (user-level takes precedence)

  system.stateVersion = "25.11";
}
