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

    users.users.${userConfig.username}.extraGroups = ["libvirtd" "kvm"];

    environment.systemPackages = with pkgs; [
      # virtiofsd backs <filesystem type="mount" driver="virtiofs"> shares.
      virtiofsd
      # Guest drivers, including the VirtIO-FS service Windows needs.
      virtio-win
      spice-gtk
    ];
  };
}
