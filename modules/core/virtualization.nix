{ config, pkgs, ... }:

{
  # 1. Kernel Optimization for AMD and Guest Latency
  boot.kernelParams = [ "kvm.poll_control=1" ];
  boot.kernelModules = [ "kvm-amd" ];

  # 2. Virtualization Daemons (Libvirt & Docker)
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };
  
  virtualisation.docker.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  # 3. Memory Locking Limits
  # Essential for performance and if you ever decide to use hugepages
  security.pam.loginLimits = [
    { domain = "@libvirtd"; item = "memlock"; type = "soft"; value = "unlimited"; }
    { domain = "@libvirtd"; item = "memlock"; type = "hard"; value = "unlimited"; }
  ];
}
