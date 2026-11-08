# ninja: high-performance desktop (Ryzen 9 9950X3D + Intel Arc B580). Zero-latency feel, high-fidelity audio, gaming throughput.
{
  pkgs,
  lib,
  inputs,
  ...
}: let
  _force = import ../../lib/mkForceIf.nix {inherit lib;};
in {
  imports = [
    ../workstation-common.nix
    ../../modules/profiles/workstation.nix
    ./hardware.nix
    ./disko.nix
    ./intel.nix
    ./network.nix
    ./udev-igc-fix.nix
    ./boot.nix
    ./kernel.nix
    ./performance.nix
    ./audio.nix
    ./chromium.nix
    ./ssh.nix
    # nixos-hardware: AMD pstate, Intel Arc GPU (xe + VA-API/VPL stack), SSD trim
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  # VM variant: neutral GPU stack, no sops secrets.
  virtualisation.vmVariant = _force.mkForceManyIf true {
    services.xserver.videoDrivers = ["modesetting"];
    hardware = {
      graphics.extraPackages = [];
    };
    sops.gnupg.home = "/tmp/gnupg";
  };

  # Host deltas: gaming clocks, thermal guard.
  mySystem = {
    gaming = {
      cpuBoostFreq = 5756452; # 5.7 GHz
      cpuBaseFreq = 4500000; # 4.5 GHz
      thermalGuard = {
        enable = true;
        throttleTemp = 90;
        recoverTemp = 80;
      };
    };
    # Tailnet routing (LAN subnet + exit node) lives on plex, which is
    # always on. This workstation is a plain tailnet client.
  };

  # System packages: audio, monitor, boot utils, uutils coreutils.
  environment.systemPackages = with pkgs; [
    libglvnd
    nmap
    alsa-utils
    libpulseaudio
    ddcutil
    sbctl
    (lib.hiPrio uutils-coreutils-noprefix)
  ];

  hardware.i2c.enable = true;

  # AppImages and native Linux games hard-code /bin/bash and /usr/bin/env.
  # envfs is a FUSE layer that resolves those paths from the caller's PATH.
  services.envfs.enable = true;
}
