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

        Prefer virtiofs where the guest can use it: it is a filesystem rather
        than an authenticated network share, so it needs no account, it is not
        bound by QEMU's single-threaded user-mode networking, and a guest
        service account can reach it. This exists for guests that cannot, and
        for Windows in particular, which needs WinFsp plus the virtio-fs driver
        from virtio-win before virtiofs works at all.

        virtiofs and kvmfr could not be combined until virtiofsd 1.14.0; see
        overlays/virtiofsd-unstable.nix for what was wrong and how it was fixed.

        QEMU's user-mode networking proxies guest connections from the host's
        own loopback, so binding Samba there makes the share reachable from the
        guest at \\10.0.2.2 and from nowhere else on the network.

        Samba authenticates against its own database, which nothing in this
        flake populates. Create the account once with `smbpasswd -a <user>`; it
        is stored in /var/lib/samba and survives rebuilds
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

    guestFilesystems = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf (lib.types.submodule ({name, ...}: {
        options = {
          source = lib.mkOption {
            type = lib.types.str;
            example = "/mnt/data/share";
            description = "Host directory to export.";
          };

          tag = lib.mkOption {
            type = lib.types.str;
            default = name;
            defaultText = lib.literalExpression "the attribute name";
            description = ''
              Mount tag the guest uses to find the share. On Windows this is the
              name virtiofs.exe is pointed at; on Linux it is the `device`
              argument to mount(8) with `-t virtiofs`.
            '';
          };
        };
      })));
      default = {};
      example = lib.literalExpression ''
        {
          win11.share.source = "/mnt/data/share";
        }
      '';
      description = ''
        virtiofs shares to offer to guests, as `<domain>.<share>`.

        This creates the directories and installs virtiofsd. libvirt reads the
        share itself from the domain XML, so the matching `<filesystem>` element
        has to exist there too:

        ```xml
        <filesystem type='mount' accessmode='passthrough'>
          <driver type='virtiofs'/>
          <source dir='/mnt/data/share'/>
          <target dir='share'/>
        </filesystem>
        ```

        The domain also needs `<memoryBacking><access mode='shared'/>`, because
        vhost-user maps guest memory into virtiofsd.
      '';
    };

    runVMsAsUser = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Run guest QEMU processes as the primary user instead of the
        `qemu-libvirtd` service account, so a guest can open disk images and
        device nodes owned by that user, `/dev/kvmfr0` among them.
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
      a defragmented zone to draw from.

      Only useful for a guest relying on transparent huge pages. It is wasted
      work, and costs the host its whole page cache on every guest start, when
      the guest takes its memory from a guestHugepagesGB reservation instead
    '';

    userNetPortForwards = lib.mkOption {
      type = with lib.types;
        attrsOf (listOf (submodule {
          options = {
            hostPort = lib.mkOption {
              type = port;
              description = "Port to listen on, on the host.";
            };

            guestPort = lib.mkOption {
              type = port;
              description = "Port to forward to, inside the guest.";
            };

            proto = lib.mkOption {
              type = enum ["tcp" "udp"];
              default = "tcp";
              description = "Transport protocol to forward.";
            };

            hostAddress = lib.mkOption {
              type = str;
              default = "127.0.0.1";
              description = ''
                Host address to bind the listening socket to. The default keeps
                the forward off the network entirely.
              '';
            };

            netdev = lib.mkOption {
              type = str;
              default = "hostnet0";
              description = ''
                QEMU netdev id of the guest's user-mode interface. libvirt names
                these hostnet0, hostnet1 and so on, in the order the interfaces
                appear in the domain XML.
              '';
            };
          };
        }));
      default = {};
      example = lib.literalExpression ''
        {
          win11 = [
            {
              hostPort = 13389;
              guestPort = 3389;
            }
          ];
        }
      '';
      description = ''
        Ports to forward into guests that use QEMU's user-mode networking,
        keyed by domain name.

        A guest behind user-mode networking is NATed and has no inbound route,
        so a forward is the only way to reach a service running in it. libvirt's
        own <portForward> element cannot express this: it rejects anything that
        is not the passt backend, and passt would change the guest's addressing
        and break the loopback SMB share. The forwards are therefore installed
        over the QEMU monitor once the guest is up.
      '';
    };

    guestHugepagesGB = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = null;
      example = 16;
      description = ''
        Gibibytes of 1 GiB hugetlb pages to reserve at boot for guest RAM.

        Transparent huge pages cannot be relied on once a guest's memory is
        shared, which it must be for virtiofs: sharing moves the allocation from
        anonymous memory to shmem, and the shmem policy `within_size` also wants
        an madvise hint that QEMU only issues for anonymous mappings. The result
        is a guest running entirely on 4 KiB pages.

        Reserving hugetlb pages sidesteps the question. The pages are real, taken
        before memory is fragmented, and never broken up or reclaimed. 1 GiB
        pages need 16 PTEs to cover a 16 GiB guest where 2 MiB pages need 8192.

        The reservation leaves host RAM for the lifetime of the boot whether or
        not a guest is running, and the domain has to ask for it:

        ```xml
        <memoryBacking>
          <hugepages>
            <page size='1048576' unit='KiB'/>
          </hugepages>
          <access mode='shared'/>
        </memoryBacking>
        ```

        1 GiB pages cannot be reserved reliably after boot, so this is a kernel
        parameter and changing it needs a reboot.
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

    boot.kernelParams = lib.optionals (cfg.guestHugepagesGB != null) [
      "hugepagesz=1G"
      "hugepages=${toString cfg.guestHugepagesGB}"
    ];

    # Reserving the pages is not enough. libvirt locates hugetlb memory by
    # scanning mounted hugetlbfs filesystems for one whose page size matches the
    # domain's request, and refuses to start with "Unable to find any usable
    # hugetlbfs mount" when none does. systemd mounts /dev/hugepages at the
    # default size, which is 2 MiB, so a 1 GiB mount has to be added alongside.
    fileSystems = lib.mkIf (cfg.guestHugepagesGB != null) {
      "/dev/hugepages1G" = {
        device = "hugetlbfs";
        fsType = "hugetlbfs";
        options = ["pagesize=1G" "mode=0755" "nosuid" "nodev"];
      };
    };

    # The scan happens once, when the QEMU driver initialises, and the result is
    # cached for the life of the daemon. Ordinary boots are fine because local
    # filesystems are mounted before any service starts, but activating this
    # configuration on a running system leaves libvirtd holding a mount list
    # from before the mount existed. Tying the restart to the reservation makes
    # that case heal itself. Restarting libvirtd does not disturb running
    # guests: the unit is KillMode=process and the QEMU processes are separate.
    systemd.services.libvirtd = lib.mkIf (cfg.guestHugepagesGB != null) {
      after = ["dev-hugepages1G.mount"];
      requires = ["dev-hugepages1G.mount"];
      restartTriggers = [(toString cfg.guestHugepagesGB)];
    };

    # libvirt runs every executable in hooks/qemu.d/ as root, passing
    # "<guest> <operation> <sub-operation> <extra>", and aborts the operation if
    # any of them exits non-zero.
    virtualisation.libvirtd.hooks.qemu =
      lib.optionalAttrs cfg.defragBeforeStart {
        # "prepare" is the only useful moment: it fires before any guest
        # resource is allocated, and once QEMU has faulted its memory in the
        # page size is already decided.
        #
        # The trailing `exit 0` matters. writeShellScript adds no `set -e`, so
        # without it the script's status is whatever the last write returned,
        # and a kernel built without CONFIG_COMPACTION would turn a skipped
        # optimisation into a refused VM start.
        defrag = pkgs.writeShellScript "libvirt-hook-defrag" ''
          [ "$2" = "prepare" ] || exit 0
          export PATH=${lib.makeBinPath [pkgs.coreutils]}

          sync
          echo 1 > /proc/sys/vm/drop_caches
          echo 1 > /proc/sys/vm/compact_memory
          exit 0
        '';
      }
      // lib.optionalAttrs (cfg.userNetPortForwards != {}) {
        # The monitor is only reachable once the domain has finished starting,
        # and libvirt holds the domain job for as long as this hook runs, so the
        # commands are issued from a detached child that retries until the job
        # is free. The child's descriptors are redirected because libvirt reads
        # the hook's output until every writer closes it, and an inherited pipe
        # would hang the start instead.
        port-forward = pkgs.writeShellScript "libvirt-hook-port-forward" ''
          [ "$2" = "started" ] || exit 0
          export PATH=${lib.makeBinPath [
            pkgs.coreutils
            pkgs.util-linux
            config.virtualisation.libvirtd.package
          ]}

          # virsh exits 0 even when the monitor rejects the command, so success
          # has to be read from the output instead: HMP prints nothing on a
          # successful hostfwd_add and an error message on anything else. A
          # non-zero exit means the monitor itself was unreachable, which is the
          # case worth retrying. Failures go to syslog because the child's own
          # output is discarded.
          add() {
            for _ in $(seq 60); do
              out=$(virsh -c qemu:///system qemu-monitor-command "$1" \
                --hmp "hostfwd_add $2" 2>&1) || {
                sleep 1
                continue
              }
              [ -z "$out" ] && return 0
              logger -t libvirt-port-forward "$1: hostfwd_add $2: $out"
              return 1
            done
            logger -t libvirt-port-forward "$1: monitor never answered, gave up on $2"
            return 1
          }

          case "$1" in
          ${
            lib.concatStringsSep "\n" (
              lib.mapAttrsToList (
                guest: forwards: ''
                  ${guest})
                    (
                  ${
                    lib.concatMapStringsSep "\n" (
                      f: "        add ${guest} '${f.netdev} ${f.proto}:${f.hostAddress}:${toString f.hostPort}-:${toString f.guestPort}'"
                    )
                    forwards
                  }
                    ) < /dev/null > /dev/null 2>&1 &
                    ;;''
              )
              cfg.userNetPortForwards
            )
          }
          esac
        '';
      };

    users.users.${userConfig.username}.extraGroups = ["libvirtd" "kvm"];

    # Exported directories have to exist and be writable by the account QEMU and
    # virtiofsd run as, which is the primary user when runVMsAsUser is set.
    # Listing them here also forces the option values, so a malformed share is
    # an eval error rather than something noticed at guest start.
    systemd.tmpfiles.rules = let
      dir = path: "d ${path} 0755 ${userConfig.username} users -";
    in
      lib.unique (
        lib.optional cfg.guestShare.enable (dir cfg.guestShare.path)
        ++ lib.concatMap (lib.mapAttrsToList (_: fs: dir fs.source))
        (lib.attrValues cfg.guestFilesystems)
      )
      # vhost-user needs the guest's RAM shared, which moves it from anonymous
      # memory to shmem. shmem has its own transparent hugepage policy, and it
      # defaults to "never", so enabling virtiofs silently drops a 16 GiB guest
      # from ~16 GiB of huge pages to none. modules/core/performance.nix sets
      # the anonymous policy to madvise; this is the shmem counterpart.
      #
      # This is a fallback for guests without a hugetlb reservation. It is not
      # enough on its own: within_size also wants an madvise hint, and QEMU only
      # issues one for anonymous mappings, so a memfd-backed guest still ends up
      # on 4 KiB pages. Use guestHugepagesGB for anything that matters.
      ++ lib.optional (cfg.guestFilesystems != {})
      "w /sys/kernel/mm/transparent_hugepage/shmem_enabled - - - - within_size";

    # virtio-win is deliberately absent: it is a ~750 MiB ISO of Windows guest
    # drivers, and the guest already has them installed. Add it back
    # temporarily when building a new Windows guest.
    environment.systemPackages =
      [pkgs.spice-gtk]
      # libvirt execs virtiofsd by path, so it only has to be installed.
      ++ lib.optional (cfg.guestFilesystems != {}) pkgs.virtiofsd;

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
