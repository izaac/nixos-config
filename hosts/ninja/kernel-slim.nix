# Slim kernel config for ninja.
#
# Strategy: override boot.kernelPackages with `ignoreConfigErrors = true`
# (per https://wiki.nixos.org/wiki/Linux_kernel#Custom_configuration), then
# apply a broad structuredExtraConfig delta via boot.kernelPatches.
#
# Why ignoreConfigErrors: NixOS's strict checker rejects two patterns that
# are unavoidable when slimming on top of common-config.nix:
#   (1) Children of disabled umbrellas become hidden ("unused" error).
#   (2) Symbols selected by other enabled drivers can't be set to n
#       ("option not set correctly").
# With ignoreConfigErrors=true, both become warnings; Kconfig's olddefconfig
# settles each symbol to whatever resolves. The wiki notes this "ignores
# potential problems" — accepted trade for slimming.
#
# Debugging "Module X not found" failures in modules-shrunk step
# --------------------------------------------------------------
# When `just build` succeeds at kernel + modules but fails at
# linux-X.Y.Z-modules-shrunk with `modprobe: FATAL: Module X not found`,
# the cause is: NixOS's initrd builder expects module X to exist, but the
# slim disabled the CONFIG_X that produces it.
#
# Two NixOS source files define which modules the initrd needs. To find
# the offending list, run from the repo root:
#
#   # Resolve the exact nixpkgs revision pinned by this flake:
#   NIXPKGS=$(nix flake metadata --json | jq -r '.locks.nodes.nixpkgs.locked | "/nix/store/\(.narHash | sub("sha256-"; ""))-source"')
#   # ...or simpler — grep every nixpkgs source unpacked in /nix/store:
#   grep -rln "MODULE_NAME_HERE" /nix/store/*-source/nixos/modules/ 2>/dev/null
#
#   1. `nixos/modules/system/boot/kernel.nix`
#      Anchor: the option name `boot.initrd.includeDefaultModules`. Find
#      the section with:
#         grep -A 60 "boot.initrd.includeDefaultModules" \
#           $NIXPKGS/nixos/modules/system/boot/kernel.nix
#      This `boot.initrd.includeDefaultModules` defaults to `true`, so the
#      unconditional module list applies to every host. Includes SATA/PATA
#      (ahci, ata_piix, pata_marvell, sata_nv, sata_via, sata_sis, sata_uli),
#      NVMe (nvme), block (sd_mod, sr_mod, mmc_block), USB (uhci_hcd,
#      ehci_hcd, ohci_hcd, xhci_hcd, usbhid), HID (hid_generic, hid_apple,
#      hid_logitech_*, hid_microsoft, hid_cherry, hid_corsair, etc.).
#
#   2. `nixos/modules/hardware/all-hardware.nix`
#      Anchor: gated by the option `hardware.enableAllHardware`. Find with:
#         grep -B 1 -A 80 "hardware.enableAllHardware" \
#           $NIXPKGS/nixos/modules/hardware/all-hardware.nix
#      ninja sets `hardware.enableAllFirmware = true` (different option), so
#      this file is NOT pulled in here. A host that enables enableAllHardware
#      would expand the required list to every PATA_*, sata_*, and server
#      SCSI driver — re-audit slim if that ever flips.
#
# Any CONFIG_X whose module name appears in either list must be kept
# enabled (left out of the disable block below), otherwise modules-shrunk
# fails and the build aborts before producing a system.
#
# What is INTENTIONALLY kept (do not strip):
#   - Steam/Proton: IA32_EMULATION, io_uring, FUTEX, ntsync, BPF, NTFS3,
#       OVERLAY_FS, FUSE, SQUASHFS (AppImages), exfat
#   - Emulators (Dolphin, RetroArch, PCSX2, RPCS3, Yuzu/Ryujinx):
#       Vulkan/OpenGL via NVIDIA, Bluetooth (Wii Remote), USB GameCube
#       adapter via HID, JIT (BPF + executable mmap)
#   - sched-ext (scx_lavd): BPF_SYSCALL, BPF_JIT, DEBUG_INFO_BTF, SCHED_CLASS_EXT
#   - Gamepads / HID: HID_NINTENDO, HID_PLAYSTATION, HID_STEAM, HID_MICROSOFT,
#       HID_LOGITECH*, HID_WIIMOTE, HID_SONY, HID_RAZER, JOYSTICK_XPAD,
#       INPUT_FF_MEMLESS
#   - Audio: ALSA/PipeWire, USB Audio, HD Audio (Realtek ALC4080)
#   - Bluetooth (full pairing path): BT_HCIBTUSB, BT_HCIBTUSB_MTK, BT_HIDP,
#       BT_RFCOMM, BT_LE_L2CAP_ECRED, A2DP
#   - Camera: V4L2 + UVC (Razer Kiyo Pro) — MEDIA_USB_SUPPORT,
#       MEDIA_CAMERA_SUPPORT, VIDEO_DEV all kept; RC_CORE/LIRC NOT touched
#       in case uvcvideo selects them
#   - Optical: ISO9660, UDF (Pioneer BD-RW)
#   - VMs: KVM_AMD, VIRTIO_*, KVM userspace (host, not guest)
#   - Storage: NVMe, ext4, LUKS (dm-crypt), vfat, exfat, FUSE, overlayfs, NTFS3
#   - RAM: TRANSPARENT_HUGEPAGE, KSM, LRU_GEN (MGLRU), ZRAM, ZSWAP, MEMFD_CREATE
#   - CPU: AMD_PSTATE, AMD_PMC, AMD_NB, AMD_IOMMU, K10TEMP, NCT6775,
#       PREEMPT_DYNAMIC, CGROUPS, SCHED_AUTOGROUP, BFQ_GROUP_IOSCHED
#   - Sensors: SENSORS_NCT6775, SENSORS_K10TEMP, SENSORS_JC42 (SPD5118),
#       SENSORS_NVME, SENSORS_AMD_ENERGY
#   - I2C: I2C_PIIX4, I2C_SMBUS, I2C_DEV (ddcutil + DDC/CI)
#   - TPM: TCG_CRB (AMD fTPM)
#   - NFS client: NFS_FS, NFS_FSCACHE (/mnt/storage)
#   - Board: ASUS_WMI, ASUS_NB_WMI, ACPI_WMI (ARGB / fan / ROG features)
#
# Hardware reference: docs/hardware.md
# Confirmed via `lspci | grep VGA`: only NVIDIA RTX 5070 Ti present.
# 9950X3D iGPU is BIOS-disabled or not exposed, so AMDGPU/RADEON are
# stripped along with the other wrong-vendor GPU drivers.
{
  lib,
  pkgs,
  ...
}: let
  off = lib.mkForce lib.kernel.no;
  on = lib.mkForce lib.kernel.yes;
in {
  # Pin kernel to Linux 7.0.10 (first version carrying the Chris Lu
  # MediaTek BT autopm fix that unbreaks MT7922 `wmt func ctrl -22`).
  # Also disable strict Kconfig checks so our slim delta can apply. The
  # slim delta itself is applied below via boot.kernelPatches.
  #
  # Note: 7.0.x is NOT an LTS line. When 7.1 lands and Chief wants to
  # move forward, replace `version`/`hash` here with the target release.
  # Compute the new hash with:
  #   nix store prefetch-file --hash-type sha256 \
  #     https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-X.Y.Z.tar.xz
  boot.kernelPackages = lib.mkForce (
    pkgs.linuxPackagesFor (pkgs.linuxPackages_latest.kernel.override {
      argsOverride = rec {
        version = "7.0.10";
        modDirVersion = "7.0.10";
        src = pkgs.fetchurl {
          url = "https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-${version}.tar.xz";
          hash = "sha256-CUl362LCDj0ZOf6BqSlYofmH8zlEblMvqGljsoBOMtw=";
        };
      };
      ignoreConfigErrors = true;
    })
  );

  boot.kernelPatches = [
    {
      name = "ninja-slim";
      patch = null;
      structuredExtraConfig = {
        # ===========================================================
        # Server / enterprise storage stacks (none on ninja)
        # ===========================================================
        INFINIBAND = off;
        INFINIBAND_IPOIB = off;
        INFINIBAND_IPOIB_CM = off;
        ISCSI_TARGET = off; # iSCSI server target
        TARGET_CORE = off; # SCSI target core (server)
        FCOE = off; # Fibre Channel over Ethernet
        FCOE_FNIC = off;
        SCSI_FC_ATTRS = off;
        SCSI_AACRAID = off; # Adaptec RAID
        SCSI_AIC79XX = off; # Adaptec aic79xx
        SCSI_AIC7XXX = off;
        SCSI_ARCMSR = off; # Areca SAS/SATA RAID
        SCSI_HPSA = off; # HP Smart Array
        SCSI_MPT3SAS = off; # Broadcom/LSI SAS 3rd gen
        SCSI_SMARTPQI = off; # Microsemi Smart Storage
        SCSI_MEGARAID = off;
        SCSI_MEGARAID_SAS = off;
        SCSI_LPFC = off; # Emulex Fibre Channel
        SCSI_QLA_FC = off; # QLogic Fibre Channel
        SCSI_QLA_ISCSI = off; # QLogic iSCSI
        CHR_DEV_ST = off; # SCSI tape
        CHR_DEV_OSST = off; # SCSI tape (OnStream)
        CHR_DEV_SCH = off; # SCSI media changer

        # ===========================================================
        # NVMe fabrics (local NVMe drives only)
        # ===========================================================
        NVME_FC = off; # Fibre Channel
        NVME_TCP = off; # NVMe over TCP
        NVME_RDMA = off; # NVMe over RDMA
        NVME_FABRICS = off; # NVMeoF core
        NVME_TARGET = off; # Target-side
        NVME_TARGET_FC = off;
        NVME_TARGET_TCP = off;
        NVME_TARGET_RDMA = off;
        NVME_AUTH = off; # Fabric auth, local only
        BLK_DEV_NVME_AUTH = off;

        # ===========================================================
        # Enterprise NICs (ninja uses Intel I225-V via IGC only)
        # ===========================================================
        MLX4_CORE = off; # Mellanox ConnectX-3
        MLX4_EN = off;
        MLX5_CORE = off; # Mellanox ConnectX-4+
        MLXSW_CORE = off; # Mellanox switch ASIC
        # Chelsio + Broadcom family skipped — CNIC select chain triggers
        # generate-config.pl repeated-question bail. The Mellanox/Aquantia/
        # IBM/Neterion entries below were safe in testing.
        SFC = off; # Solarflare
        SFC_SIENA = off;
        I40E = off; # Intel server NICs
        IXGBE = off;
        IXGB = off;
        ICE = off;
        IGB = off; # Intel 1GbE server (we use IGC)
        IXGBEVF = off;
        MYRI10GE = off; # Myricom 10GbE
        QLCNIC = off; # QLogic
        QLGE = off;
        NETXEN_NIC = off;
        LIQUIDIO = off; # Cavium
        THUNDER_NIC_PF = off;
        ATL1 = off; # Aquantia/Atheros
        ATL1C = off;
        ATL2 = off;
        ALX = off;
        ATLANTIC = off;
        IBMVETH = off; # IBM POWER NIC
        EHEA = off;
        S2IO = off; # Neterion
        VXGE = off;

        # ===========================================================
        # Hypervisor guest support (ninja is a bare-metal host)
        # ===========================================================
        XEN = off;
        XEN_PV = off;
        XEN_PVH = off;
        XEN_PVHVM = off;
        XEN_DOM0 = off;
        XEN_BALLOON = off;
        XEN_GNTDEV = off;
        XEN_BLKDEV_FRONTEND = off;
        XEN_NETDEV_FRONTEND = off;
        XEN_PCIDEV_FRONTEND = off;
        XEN_SCSI_FRONTEND = off;
        XEN_FBDEV_FRONTEND = off;
        KVM_XEN = off; # Xen hypercall emulation in KVM
        HYPERV = off; # Microsoft Hyper-V guest
        HYPERV_STORAGE = off;
        HYPERV_NET = off;
        HYPERV_KEYBOARD = off;
        HYPERV_BALLOON = off;
        HYPERV_UTILS = off;
        HYPERV_VSOCKETS = off;
        MSHV_ROOT = off;
        VMWARE_BALLOON = off;
        VMWARE_PVSCSI = off;
        VMWARE_VMCI = off;
        VMWARE_VMCI_VSOCKETS = off;
        VMXNET3 = off;
        FUJITSU_ES = off;
        JAILHOUSE_GUEST = off;
        ACRN_GUEST = off;

        # ===========================================================
        # Server CPU features / exotic x86
        # ===========================================================
        X86_NUMACHIP = off; # Numascale interconnect
        X86_UV = off; # SGI Ultraviolet
        CALGARY_IOMMU = off; # IBM PowerPC IOMMU on x86
        GART_IOMMU = off; # Legacy AMD GART (Zen uses AMD-Vi)
        X86_MCE_AMD_INJ = off; # MCE injection test

        # ===========================================================
        # Intel-specific CPU code (ninja is AMD-only)
        # ===========================================================
        INTEL_IDLE = off; # AMD uses acpi_idle
        X86_INTEL_LPSS = off; # Intel SoC chipsets
        INTEL_TDX_HOST = off; # Trust Domain Extensions
        INTEL_TDX_GUEST = off;
        X86_INTEL_TSX_MODE_OFF = off;
        X86_INTEL_TSX_MODE_ON = off;
        X86_INTEL_TSX_MODE_AUTO = off;
        # NOTE: CPU_SUP_INTEL kept (perf/microcode tooling may depend)

        # ===========================================================
        # IPMI + server watchdogs (consumer X670E, no BMC)
        # ===========================================================
        IPMI_HANDLER = off;
        IPMI_SI = off;
        IPMI_DEVICE_INTERFACE = off;
        IPMI_WATCHDOG = off;
        IPMI_SSIF = off;
        IPMI_POWEROFF = off;
        W83627HF_WDT = off;
        W83877F_WDT = off;
        W83977F_WDT = off;
        IT8712F_WDT = off;
        IB700_WDT = off;
        WAFER_WDT = off;
        MACHZ_WDT = off;
        SBC_FITPC2_WATCHDOG = off;
        INTEL_MID_WATCHDOG = off;
        MEN_A21_WDT = off;
        ITCO_WDT = off; # Intel TCO (AMD uses SP5100, blacklisted)
        # SOFTDOG kept

        # ===========================================================
        # HWMON drivers for chips not on this board
        # KEEP: SENSORS_NCT6775, SENSORS_K10TEMP, SENSORS_JC42 (SPD5118),
        #       SENSORS_NVME, SENSORS_AMD_ENERGY
        # ===========================================================
        SENSORS_W83627HF = off;
        SENSORS_W83627EHF = off;
        SENSORS_W83781D = off;
        SENSORS_W83791D = off;
        SENSORS_W83792D = off;
        SENSORS_W83793 = off;
        SENSORS_W83795 = off;
        SENSORS_IT87 = off;
        SENSORS_F71805F = off;
        SENSORS_F71882FG = off;
        SENSORS_F75375S = off;
        SENSORS_FSCHMD = off;
        SENSORS_SMSC47M1 = off;
        SENSORS_SMSC47M192 = off;
        SENSORS_SMSC47B397 = off;
        SENSORS_SCH56XX_COMMON = off;
        SENSORS_SCH5627 = off;
        SENSORS_SCH5636 = off;
        SENSORS_ADM1021 = off;
        SENSORS_ADM1025 = off;
        SENSORS_ADM1026 = off;
        SENSORS_ADM1029 = off;
        SENSORS_ADM1031 = off;
        SENSORS_ADM1275 = off;
        SENSORS_ADT7411 = off;
        SENSORS_ADT7462 = off;
        SENSORS_ADT7470 = off;
        SENSORS_ADT7475 = off;
        SENSORS_LM63 = off;
        SENSORS_LM73 = off;
        SENSORS_LM75 = off;
        SENSORS_LM77 = off;
        SENSORS_LM78 = off;
        SENSORS_LM80 = off;
        SENSORS_LM83 = off;
        SENSORS_LM85 = off;
        SENSORS_LM87 = off;
        SENSORS_LM92 = off;
        SENSORS_LM93 = off;
        SENSORS_LM95234 = off;
        SENSORS_LM95241 = off;
        SENSORS_LM95245 = off;
        SENSORS_VIA_CPUTEMP = off;
        SENSORS_VIA686A = off;
        SENSORS_CORETEMP = off; # Intel CPU temp
        SENSORS_DME1737 = off;
        SENSORS_PC87360 = off;
        SENSORS_PC87427 = off;
        SENSORS_GL518SM = off;
        SENSORS_GL520SM = off;
        SENSORS_SIS5595 = off;
        SENSORS_ASB100 = off;
        SENSORS_ASC7621 = off;
        SENSORS_ATXP1 = off;

        # ===========================================================
        # Laptop / mobile platform drivers (ninja is a desktop)
        # KEEP: ASUS_WMI, ASUS_NB_WMI, ACPI_WMI for ROG ARGB/fan
        # ===========================================================
        ACPI_TOSHIBA = off;
        ACPI_PANASONIC = off;
        DELL_LAPTOP = off;
        DELL_SMBIOS = off;
        DELL_RBTN = off;
        ASUS_LAPTOP = off; # not the same as ASUS_WMI
        EEEPC_LAPTOP = off;
        EEEPC_WMI = off;
        LENOVO_YMC = off;
        THINKPAD_ACPI = off;
        IDEAPAD_LAPTOP = off;
        SONY_LAPTOP = off;
        HP_ACCEL = off;
        HP_WMI = off;
        HP_WIRELESS = off;
        SAMSUNG_LAPTOP = off;
        SAMSUNG_Q10 = off;
        MSI_LAPTOP = off;
        MSI_WMI = off;
        COMPAL_LAPTOP = off;
        FUJITSU_LAPTOP = off;
        FUJITSU_TABLET = off;
        INSPUR_PLATFORM_PROFILE = off;
        ACER_WMI = off;
        ACERHDF = off;
        WMI_BMOF = off;

        # ===========================================================
        # Battery / charger drivers (desktop, no battery)
        # ===========================================================
        BATTERY_BQ27XXX = off;
        BATTERY_DS2780 = off;
        BATTERY_DS2781 = off;
        BATTERY_DS2760 = off;
        BATTERY_SBS = off;
        BATTERY_MAX17040 = off;
        BATTERY_MAX17042 = off;
        BATTERY_RT5033 = off;
        CHARGER_BQ2415X = off;
        CHARGER_BQ24190 = off;
        CHARGER_BQ24735 = off;
        CHARGER_BQ25890 = off;
        CHARGER_LP8727 = off;
        CHARGER_LT3651 = off;
        CHARGER_MAX14577 = off;
        CHARGER_MAX77693 = off;
        CHARGER_SMB347 = off;
        CHARGER_TPS65090 = off;
        AB8500_BATTERY = off;
        INPUT_AXP20X_PEK = off; # X-Powers PMIC

        # ===========================================================
        # Legacy / dead network protocols
        # ===========================================================
        ATM = off;
        X25 = off;
        LAPB = off;
        AX25 = off; # Amateur radio
        NETROM = off; # child of AX25
        ROSE = off; # child of AX25
        TIPC = off; # Cluster messaging (HPC/server)
        RDS = off; # Reliable Datagram Sockets

        # ===========================================================
        # Niche protocols / tunnels (not used)
        # KEEP: WIREGUARD, VXLAN, PPP/PPPOE (VPN)
        # ===========================================================
        SCTP = off; # telecom/SS7
        L2TP = off;
        L2TP_V3 = off;
        L2TP_IP = off;
        L2TP_ETH = off;
        MPLS_ROUTING = off;
        MPLS_IPTUNNEL = off;
        NET_MPLS_GSO = off;
        OPENVSWITCH = off; # podman uses netavark
        "6LOWPAN" = off; # IoT mesh (attr name must be quoted: starts with digit)
        IEEE802154 = off;
        MAC80211_MESH = off;
        BATMAN_ADV = off;
        NET_DSA = off; # network switch ASICs (umbrella)

        # ===========================================================
        # WAN/HDLC legacy
        # ===========================================================
        HDLC = off;
        HDLC_RAW = off;
        HDLC_PPP = off;
        HDLC_CISCO = off;
        HDLC_FR = off; # Frame Relay
        SLIP = off; # serial line IP
        PLIP = off; # parallel line IP (parport already off)
        FDDI = off;
        HIPPI = off; # supercomputer interconnect

        # ===========================================================
        # Cellular / WWAN (no modem present)
        # ===========================================================
        WWAN = off;
        # MHI_BUS/MHI_NET skipped — selected by ATH11K/ATH12K WiFi drivers
        # in common-config (Qualcomm WiFi 6/7 chains)
        CAIF = off; # ST-Ericsson
        USB_SIERRA_NET = off;
        USB_HSO = off;

        # ===========================================================
        # Hardware buses / dial-up ninja does not have
        # ===========================================================
        ISDN = off;
        PARPORT = off; # No parallel port on X670E-F
        CAN = off; # Automotive Controller Area Network

        # ===========================================================
        # NFS server (ninja is client-only; mySystem.core.nfs=false)
        # ===========================================================
        NFSD = off;
        NFSD_V3_ACL = off;
        NFSD_V4 = off;
        NFSD_V4_SECURITY_LABEL = off;
        NFS_LOCALIO = off;

        # ===========================================================
        # Legacy filesystems unused
        # (root=ext4, boot=vfat, removable=exfat; ext4/btrfs/xfs/NTFS3 kept)
        # ===========================================================
        JFS_FS = off;
        NILFS2_FS = off;
        F2FS_FS = off;
        F2FS_FS_COMPRESSION = off;
        GFS2_FS = off; # Cluster FS (server)
        OCFS2_FS = off; # Oracle Cluster FS (server)
        HFS_FS = off;
        HFSPLUS_FS = off;
        SYSV_FS = off;
        UFS_FS = off;
        MINIX_FS = off;
        BFS_FS = off;
        ROMFS_FS = off;
        AFS_FS = off; # Andrew File System
        ECRYPT_FS = off; # eCryptfs (LUKS used instead)
        ORANGEFS_FS = off; # Parallel FS
        NTFS_FS = off; # legacy NTFS driver (NTFS3 kept)
        JFFS2_FS = off; # JFFS2 for embedded flash
        UBIFS_FS = off; # UBIFS for embedded
        CRAMFS = off;
        # KEPT: ISO9660_FS, UDF_FS (BD-RW), NTFS3, BTRFS, XFS, SQUASHFS

        # ===========================================================
        # Filesystem feature trims (debug/optional)
        # ===========================================================
        XFS_RT = off; # XFS realtime subvolume
        XFS_ONLINE_SCRUB = off;
        EXT4_FS_VERITY = off; # fs-verity not in use
        BTRFS_FS_REF_VERIFY = off;
        BTRFS_FS_RUN_SANITY_TESTS = off;
        BTRFS_DEBUG = off;
        BTRFS_ASSERT = off;
        CIFS_SMB_DIRECT = off; # SMB over RDMA
        CIFS_FSCACHE = off; # SMB-side fscache
        "9P_FS" = off; # Plan 9 (only useful as a VM guest)

        # ===========================================================
        # Legacy partition tables (keep EFI/MSDOS for boot)
        # ===========================================================
        MAC_PARTITION = off;
        LDM_PARTITION = off; # Windows dynamic disks
        SGI_PARTITION = off;
        ULTRIX_PARTITION = off;
        SUN_PARTITION = off;
        KARMA_PARTITION = off;
        SYSV68_PARTITION = off;
        OSF_PARTITION = off;
        AIX_PARTITION = off;
        ACORN_PARTITION = off;
        ATARI_PARTITION = off;
        AMIGA_PARTITION = off;

        # ===========================================================
        # PATA / legacy SATA / floppy skipped entirely — NixOS's standard
        # initrd module list (pata_piix, pata_marvell, pata_amd, ata_piix,
        # sata_sil, etc.) is unconditional, so disabling any of them
        # breaks the modules-shrunk step. Marginal slim value lost.
        # ===========================================================
        BLK_DEV_PCIESSD_MTIP32XX = off; # Micron PCIe SSD (not in initrd list)

        # ===========================================================
        # DM / MD targets unused (LUKS only — DM_CRYPT kept)
        # ===========================================================
        MD_RAID0 = off;
        MD_RAID1 = off;
        MD_RAID10 = off;
        MD_RAID456 = off;
        MD_MULTIPATH = off;
        MD_FAULTY = off; # test-only
        BCACHE = off; # no SSD-as-cache layout
        DM_MULTIPATH = off; # single-path NVMe
        DM_THIN_PROVISIONING = off;
        DM_CACHE = off;
        DM_CACHE_SMQ = off;
        DM_ERA = off;
        DM_WRITECACHE = off;
        DM_EBS = off;
        DM_CLONE = off;
        DM_DELAY = off; # debug
        DM_LOG_WRITES = off; # debug
        DM_ZONED = off; # zoned-block (SMR)

        # ===========================================================
        # Niche block / network block devices
        # ===========================================================
        NBD = off; # Network Block Device
        BLK_DEV_DRBD = off; # Distributed Replicated BD
        BLK_DEV_RBD = off; # Ceph RADOS BD

        # ===========================================================
        # MTD (embedded NOR/NAND flash — none on X670E-F)
        # ===========================================================
        MTD = off;

        # ===========================================================
        # PCMCIA / Cardbus (no card slot on AM5)
        # ===========================================================
        PCMCIA = off;
        CARDBUS = off;
        YENTA = off;

        # ===========================================================
        # TV tuners / radio / SDR (no card present).
        # KEEP MEDIA_USB_SUPPORT + V4L2 + UVC for Razer Kiyo Pro.
        # ===========================================================
        MEDIA_ANALOG_TV_SUPPORT = off;
        MEDIA_DIGITAL_TV_SUPPORT = off;
        MEDIA_RADIO_SUPPORT = off;
        MEDIA_SDR_SUPPORT = off;
        MEDIA_CEC_SUPPORT = off; # HDMI CEC (GPU side, not camera)
        # NOTE: RC_CORE / LIRC NOT disabled — uvcvideo might select RC_CORE

        # ===========================================================
        # GPU drivers not used (NVIDIA proprietary only — no AMD iGPU exposed)
        # ===========================================================
        DRM_NOUVEAU = off; # Open NVIDIA — using proprietary nvidia.ko
        DRM_NOUVEAU_SVM = off;
        DRM_I915 = off; # Intel integrated GPU
        DRM_I915_GVT = off;
        DRM_I915_GVT_KVMGT = off;
        DRM_XE = off; # Intel Xe
        DRM_VMWGFX = off; # VMware SVGA
        DRM_QXL = off; # QEMU QXL paravirt
        DRM_AMDGPU = off; # iGPU not exposed on ninja
        DRM_AMDGPU_SI = off; # Southern Islands legacy
        DRM_AMDGPU_CIK = off; # Sea Islands legacy
        DRM_AMD_DC_FP = off;
        HSA_AMD = off; # ROCm/compute via AMDGPU
        DRM_RADEON = off; # Older AMD GPUs (pre-AMDGPU)
        # KEPT: NVIDIA out-of-tree module via hardware.nvidia.*

        # ===========================================================
        # KVM Intel (ninja is AMD); SGX/KVM child
        # ===========================================================
        KVM_INTEL = off;
        X86_SGX_KVM = off;

        # ===========================================================
        # WiFi drivers for chipsets not present
        # ninja: MediaTek MT7922 (MT76 family) — keep MT76*
        # ===========================================================
        IWLWIFI = off; # Intel WiFi
        ATH9K = off;
        ATH9K_HTC = off;
        ATH5K = off;
        ATH6KL = off;
        B43 = off; # Broadcom legacy
        B43LEGACY = off;
        BRCMSMAC = off;
        BRCMFMAC = off;
        IPW2100 = off; # Pre-iwlwifi Intel
        IPW2200 = off;
        RTL8180 = off; # Old Realtek PCI
        RTL8187 = off;
        RTW88 = off; # Modern Realtek 8822
        RTW89 = off; # Realtek 8852
        RTL8XXXU = off; # Realtek USB WiFi
        RTLWIFI = off; # Older Realtek PCIe WiFi
        CARL9170 = off; # Atheros AR9170 USB
        ZD1211RW = off; # ZyDAS USB
        ORINOCO = off; # Hermes
        WL12XX = off; # TI WiLink
        WL18XX = off;
        WLCORE = off;
        QTNFMAC = off; # Quantenna
        RSI_91X = off; # Redpine
        MWL8K = off; # Marvell
        MWIFIEX = off;
        P54_COMMON = off; # Prism54
        RT2X00 = off; # Ralink legacy
        WILC1000 = off; # Microchip

        # ===========================================================
        # Legacy sound stacks (PipeWire/ALSA only)
        # KEEP: SND_HDA*, SND_USB_*, NVIDIA HDMI audio
        # ===========================================================
        SOUND_OSS_CORE = off;
        SND_OSSEMUL = off;
        SND_AD1816A = off; # ISA AD1816A
        SND_CMI8330 = off; # ISA C-Media
        SND_ES1688 = off; # ISA ESS
        SND_SB16 = off; # ISA SoundBlaster
        SND_SB8 = off;
        SND_SBAWE = off; # AWE32/64
        SND_AU8810 = off; # Aureal Vortex
        SND_AU8820 = off;
        SND_AU8830 = off;
        SND_VIA82XX = off; # VIA southbridge audio
        SND_VIA82XX_MODEM = off;
        SND_VX222 = off; # Digigram VX222
        SND_ENS1370 = off; # Ensoniq AudioPCI
        SND_ENS1371 = off;
        SND_CS5535AUDIO = off; # AMD Geode SoC
        SND_OPL3_LIB = off; # FM synth lib
        SND_MPU401 = off; # MIDI port iface
        SND_PCSP = off; # PC speaker (pcspkr blacklisted)

        # ===========================================================
        # HID quirk drivers for peripherals not present.
        # KEEP: HID_NINTENDO, HID_PLAYSTATION, HID_SONY, HID_MICROSOFT,
        #       HID_STEAM, HID_LOGITECH*, HID_WIIMOTE, HID_RAZER,
        #       JOYSTICK_XPAD, HID_GENERIC, HID_MULTITOUCH
        # ===========================================================
        HID_APPLEIR = off;
        HID_ICADE = off;
        HID_PRODIKEYS = off;
        HID_GFRM = off; # GameStop gamepad
        HID_GREENASIA = off;
        HID_TWINHAN = off; # Twinhan IR
        HID_KENSINGTON = off;
        HID_HOLTEK = off;
        HID_HYPERV_MOUSE = off; # Hyper-V guest only
        HID_PETALYNX = off;
        HID_PICOLCD = off;
        HID_PRIMAX = off;
        HID_RMI = off; # Synaptics RMI4 touchpad
        HID_SAITEK = off;
        HID_TIVO = off;
        HID_TOPSEED = off;
        HID_UCLOGIC = off; # UC-Logic tablet
        HID_WALTOP = off;
        HID_GT683R = off; # MSI GT683R LED keys
        HID_BIGBENFF = off;

        # ===========================================================
        # Input devices — hardware absent
        # KEEP: INPUT_FF_MEMLESS (rumble), INPUT_EVDEV, INPUT_JOYDEV
        # ===========================================================
        INPUT_TOUCHSCREEN = off;
        INPUT_TABLET = off;
        RMI4_CORE = off;
        INPUT_AD714X = off;
        INPUT_MMA8450 = off;
        INPUT_PCF8574 = off;
        INPUT_GPIO_BEEPER = off;
        INPUT_GPIO_DECODER = off;
        INPUT_GPIO_VIBRA = off;

        # ===========================================================
        # Legacy joysticks (gameport/parport/serial — pre-USB era)
        # KEEP: JOYSTICK_XPAD for Xbox controllers
        # ===========================================================
        JOYSTICK_DB9 = off;
        JOYSTICK_TURBOGRAFX = off;
        JOYSTICK_GRIP = off;
        JOYSTICK_GUILLEMOT = off;
        JOYSTICK_INTERACT = off;
        JOYSTICK_MAGELLAN = off;
        JOYSTICK_SIDEWINDER = off;
        JOYSTICK_SPACEORB = off;
        JOYSTICK_STINGER = off;
        JOYSTICK_TWIDJOY = off;
        JOYSTICK_WARRIOR = off;
        JOYSTICK_ZHENHUA = off;

        # ===========================================================
        # Crypto algo disables removed — CRYPTO_TEST and similar kernel-
        # internal selectors force these on, causing generate-config.pl
        # to bail. Marginal slim value lost.
        # ===========================================================

        # ===========================================================
        # Misc legacy / unused hardware
        # KEEP: TCG_CRB (AMD fTPM), RTC_DRV_CMOS, SATA_AHCI
        # ===========================================================
        NVRAM = off; # /dev/nvram vestigial
        EISA = off; # EISA bus
        MCA = off; # IBM Micro Channel
        SGI_IOC4 = off;
        SGI_GRU = off;
        GOLDFISH = off; # Android emulator host
        GOLDFISH_PIPE = off;
        TCG_INFINEON = off; # discrete TPM
        TCG_NSC = off;
        TCG_ATMEL = off;
        TCG_ST33_I2C = off;
        SERIAL_8250_FINTEK = off;
        SERIAL_8250_EXAR = off;
        SERIAL_8250_MID = off;
        SERIAL_8250_LPSS = off; # Intel low-power
        PRINTER = off; # parallel printer
        HW_RANDOM_TIMERIOMEM = off;
        HANGCHECK_TIMER = off; # mainframe
        MISC_RTSX_PCI = off; # Realtek card reader
        MISC_RTSX_USB = off;

        # ===========================================================
        # Firmware loader user-helper (deprecated, security risk)
        # ===========================================================
        FW_LOADER_USER_HELPER = off;
        FW_LOADER_USER_HELPER_FALLBACK = off;

        # ===========================================================
        # Hibernation (no swap partition — ZRAM only). Sleep/suspend kept.
        # ===========================================================
        HIBERNATION = off;

        # ===========================================================
        # Old framebuffer drivers (KMS via DRM is the path)
        # ===========================================================
        FB_TFT = off; # Tiny SPI displays
        FB_RADEON = off; # Old radeon fbdev

        # ===========================================================
        # NOTE: LIBNVDIMM/DAX removed — even with ignoreConfigErrors,
        # the generate-config.pl script bails on "repeated question"
        # because X86_PMEM_LEGACY/ACPI_NFIT `select` LIBNVDIMM.
        # ===========================================================

        # ===========================================================
        # Hardening (force-enable; most are default y in modern kernels)
        # ===========================================================
        LEGACY_PTYS = off; # Old /dev/ptyXX
        STRICT_DEVMEM = on;
        IO_STRICT_DEVMEM = on;
        HARDENED_USERCOPY = on;
        RANDOMIZE_BASE = on; # KASLR
        RANDOMIZE_MEMORY = on;

        # ===========================================================
        # Pin critical gaming/emulator options (defaults but explicit
        # so future kernel bumps surface any regression)
        # ===========================================================
        IA32_EMULATION = on; # 32-bit Steam runtime, legacy emulators
        X86_X32_ABI = off; # X32 ABI is dead, not needed
      };
    }
  ];
}
