{ config, pkgs, ... }:

{
  # 1. Virtualization Daemons (Libvirt & Docker)
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;

      verbatimConfig = ''
        cgroup_device_acl = [
          "/dev/null", "/dev/full", "/dev/zero",
          "/dev/random", "/dev/urandom",
          "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
          "/dev/rtc","/dev/hpet",
          "/dev/dri/renderD128"
        ]
      '';
    };
  };
  
  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;

  # 2. Memory Locking Limits
  # Essential for performance and if you ever decide to use hugepages
  security.pam.loginLimits = [
    { domain = "@libvirtd"; item = "memlock"; type = "soft"; value = "unlimited"; }
    { domain = "@libvirtd"; item = "memlock"; type = "hard"; value = "unlimited"; }
  ];
  
  # 3. This helps SPICE/QEMU find the correct EGL display
  environment.sessionVariables = {
    EGL_PLATFORM = "wayland"; 
  };
}

