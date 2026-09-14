{
  config,
  lib,
  pkgs,
  userConfig,
  ...
}: let
  cfg = config.mySystem.core.libvirt;
in {
  options.mySystem.core.libvirt = {
    enable = lib.mkEnableOption "libvirtd, QEMU/KVM and virt-manager";

    extraDeviceACL = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["/dev/kvmfr0"];
      description = ''
        Device nodes to add to libvirt's cgroup allow-list, on top of its
        defaults. A guest cannot open a device that is not listed here, however
        permissive the filesystem permissions are.
      '';
    };

    guestShare = {
      enable = lib.mkEnableOption ''
        an SMB share for VM guests, bound to loopback.

        virtiofs would be the obvious choice, but it cannot be used alongside
        kvmfr: vhost-user hands every guest memory region to virtiofsd, which
        sizes each one with seek(SEEK_END), and /dev/kvmfr0 is a character
        device that only supports mmap. virtiofsd dies with
        "Illegal seek" (ESPIPE) as soon as the guest starts.

        SMB has no such conflict, and Windows mounts it natively. QEMU's
        user-mode networking proxies guest connections from the host's own
        loopback, so binding Samba there makes the share reachable from the
        guest at \\10.0.2.2 and from nowhere else on the network
      '';

      path = lib.mkOption {
        type = lib.types.str;
        example = "/home/izaac/Documents";
        description = "Directory to export.";
      };

      name = lib.mkOption {
        type = lib.types.str;
        default = "share";
        description = "Share name, as it appears in the guest.";
      };
    };

    runVMsAsUser = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Run guest QEMU processes as the primary user instead of the
        `qemu-libvirtd` service account. This is what makes a virtiofs share of
        the user's home directory work: virtiofsd inherits the QEMU process
        credentials, and the service account cannot read `/home`.
      '';
    };

    defragBeforeStart = lib.mkEnableOption ''
      compacting host memory before a guest starts.

      A guest whose RAM is preallocated needs thousands of physically
      contiguous 2 MiB blocks to be backed by transparent huge pages. On a host
      that has been running for a while the buddy allocator has almost none
      left, so most of the guest silently falls back to 4 KiB pages and then
      spends its whole life missing the TLB.

      Page cache is both reclaimable and the main thing fragmenting the zone,
      so this drops it and then runs a compaction pass, giving the allocation
      a defragmented zone to draw from
    '';
  };

  config = lib.mkIf cfg.enable {
    virtualisation.libvirtd = {
      enable = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
      qemu = {
        package = pkgs.qemu_kvm;
        # The NixOS module writes `user`/`group` into qemu.conf only when
        # runAsRoot is false, and libvirt's parser honours the *first*
        # definition of a key (virConfGetValue walks the entry list and returns
        # on the first name match). Appending our own lines after the module's
        # would therefore be silently ignored, so suppressing them is the only
        # way to pin the guest process to another account. Setting runAsRoot
        # here does not actually run QEMU as root: it merely stops those two
        # lines from being emitted, and the verbatim block below supplies the
        # unprivileged account instead.
        runAsRoot = cfg.runVMsAsUser;
        # OVMF images ship with QEMU as of 26.05, so only the TPM emulator that
        # Windows 11 requires still needs enabling here.
        swtpm.enable = true;
        verbatimConfig =
          lib.optionalString cfg.runVMsAsUser ''
            user = "${userConfig.username}"
            group = "kvm"
          ''
          # Replaces rather than extends libvirt's list, so the defaults have to
          # be repeated here.
          + lib.optionalString (cfg.extraDeviceACL != []) ''
            cgroup_device_acl = [
              ${
              lib.concatMapStringsSep "\n  " (d: "\"${d}\",") (
                [
                  "/dev/null"
                  "/dev/full"
                  "/dev/zero"
                  "/dev/random"
                  "/dev/urandom"
                  "/dev/ptmx"
                  "/dev/kvm"
                ]
                ++ cfg.extraDeviceACL
              )
            }
            ]
          '';
      };
    };

    programs.virt-manager.enable = true;

    # libvirt runs every executable in hooks/qemu.d/ as root, passing
    # "<guest> <operation> <sub-operation> <extra>". "prepare" fires before any
    # guest resource is allocated, which is the only useful moment: once QEMU
    # has faulted its memory in, the page size is already decided.
    virtualisation.libvirtd.hooks.qemu = lib.mkIf cfg.defragBeforeStart {
      defrag = pkgs.writeShellScript "libvirt-hook-defrag" ''
        [ "$2" = "prepare" ] || exit 0

        ${pkgs.coreutils}/bin/sync
        echo 1 > /proc/sys/vm/drop_caches
        echo 1 > /proc/sys/vm/compact_memory
      '';
    };

    users.users.${userConfig.username}.extraGroups = ["libvirtd" "kvm"];

    # virtio-win is deliberately absent: it is a ~750 MiB ISO of Windows guest
    # drivers, and the guest already has them installed. Add it back
    # temporarily when building a new Windows guest.
    environment.systemPackages = with pkgs; [
      # virtiofsd backs <filesystem type="mount" driver="virtiofs"> shares.
      virtiofsd
      spice-gtk
    ];

    services.samba = lib.mkIf cfg.guestShare.enable {
      enable = true;
      # The guest connects to a fixed address, so NetBIOS name resolution and
      # winbind are both dead weight and extra listening sockets.
      nmbd.enable = false;
      winbindd.enable = false;
      openFirewall = false;

      settings = {
        global = {
          "interfaces" = "lo";
          "bind interfaces only" = "yes";
          "security" = "user";
          "server min protocol" = "SMB3";
          "load printers" = "no";
          "printcap name" = "/dev/null";
          "disable spoolss" = "yes";
        };

        ${cfg.guestShare.name} = {
          "path" = cfg.guestShare.path;
          "browseable" = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "force user" = userConfig.username;
        };
      };
    };
  };
}
