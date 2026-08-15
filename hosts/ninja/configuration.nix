# ninja: high-performance desktop (Ryzen 9 9950X3D + NVIDIA). Zero-latency feel, high-fidelity audio, gaming throughput.
{
  pkgs,
  lib,
  inputs,
  siteConfig,
  ...
}: {
  imports = [
    ../common.nix
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
    # nixos-hardware: AMD pstate, NVIDIA (nonprime/desktop), SSD trim
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia-nonprime
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  # VM variant: disable NVIDIA, no sops secrets.
  virtualisation.vmVariant = {
    # VM: disable NVIDIA, use modesetting, no sops.
    services.xserver.videoDrivers = lib.mkForce ["modesetting"];
    hardware = {
      nvidia.package = lib.mkForce pkgs.hello;
      graphics.extraPackages = lib.mkForce [];
      # VM: disable nvidia-container-toolkit.
      nvidia-container-toolkit.enable = lib.mkForce false;
    };
    systemd.services.nvidia-lock-clocks.enable = lib.mkForce false;
    # VM: no sops secrets needed.
    sops.gnupg.home = lib.mkForce "/tmp/gnupg";
  };

  # Host deltas: gaming clocks, thermal guard, tailscale routes.
  mySystem = {
    gaming = {
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
      advertiseRoutes = [siteConfig.subnet];
      routingInterface = "eno1";
    };
  };

  # System packages: audio, monitor, boot utils, uutils coreutils.
  environment.systemPackages = with pkgs; [
    libglvnd
    parted
    nmap
    alsa-utils
    libpulseaudio
    ddcutil
    sbctl
    (lib.hiPrio uutils-coreutils-noprefix)
  ];

  hardware.i2c.enable = true;
}
