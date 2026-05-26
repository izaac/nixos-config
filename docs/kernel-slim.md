# Slim Kernel (ninja)

> **Source**: `hosts/ninja/kernel-slim.nix`
> **Applies to**: ninja only (windy uses stock `pkgs.linuxPackages_latest`)

## What this does

Strips kernel drivers/subsystems ninja's hardware will never use (wrong-vendor
WiFi/GPU, dial-up, parallel port, CAN bus, server SCSI/HBAs, legacy
filesystems, laptop platform drivers, etc.) and applies a few hardening flips.
Around **14.7% fewer enabled options** and **15% fewer modules built** vs the
stock kernel — mostly attack-surface reduction, since unused modules never
loaded anyway.

## How it is wired

Two things happen in `hosts/ninja/kernel-slim.nix`:

1. **Pin + override the kernel package**

   ```nix
   boot.kernelPackages = lib.mkForce (
     pkgs.linuxPackagesFor (pkgs.linuxPackages_latest.kernel.override {
       argsOverride = { version = "7.0.10"; ... };
       ignoreConfigErrors = true;
     })
   );
   ```

   - `argsOverride` pins the kernel source tarball to a known-good release
     (currently 7.0.10 — the first version carrying the Chris Lu MediaTek BT
     autopm fix for MT7922 `wmt func ctrl -22`). NVIDIA + userspace continue
     updating freely against this pinned kernel.
   - `ignoreConfigErrors = true` is required because NixOS's strict checker
     would otherwise reject our slim deltas (see "Why ignoreConfigErrors").

2. **Apply the slim delta via `boot.kernelPatches[].structuredExtraConfig`**

   Each `CONFIG_X = off` is `lib.mkForce lib.kernel.no`. The `off` and `on`
   helpers at the top of the file bake the `mkForce` in so entries stay one
   line.

## Why `ignoreConfigErrors = true`

The strict checker rejects two patterns that are unavoidable when slimming on
top of nixpkgs' `common-config.nix`:

1. Children of disabled umbrellas become hidden → "unused option" error
2. Symbols selected by other enabled drivers can't be set to n → "option not
   set correctly" error

With `ignoreConfigErrors = true`, both become warnings and Kconfig's
`olddefconfig` settles each symbol to whatever resolves. The
[NixOS wiki page on custom kernel configuration](https://wiki.nixos.org/wiki/Linux_kernel#Custom_configuration)
notes this "ignores potential problems" — accepted trade for slimming.

## What is INTENTIONALLY kept

Do not strip anything that supports these paths:

- **Steam / Proton**: `IA32_EMULATION`, `io_uring`, `FUTEX`, `ntsync`, `BPF`,
  `NTFS3`, `OVERLAY_FS`, `FUSE`, `SQUASHFS` (AppImages), `exfat`
- **Emulators** (Dolphin, RetroArch, PCSX2, RPCS3, Yuzu/Ryujinx): Vulkan/OpenGL
  via NVIDIA, Bluetooth (Wii Remote pairing), USB GameCube adapter via HID, JIT
  (BPF + executable mmap)
- **sched-ext (`scx_lavd`)**: `BPF_SYSCALL`, `BPF_JIT`, `DEBUG_INFO_BTF`,
  `SCHED_CLASS_EXT`
- **Gamepads / HID**: `HID_NINTENDO`, `HID_PLAYSTATION`, `HID_STEAM`,
  `HID_MICROSOFT`, `HID_LOGITECH*`, `HID_WIIMOTE`, `HID_SONY`, `HID_RAZER`,
  `JOYSTICK_XPAD`, `INPUT_FF_MEMLESS`
- **Audio**: ALSA/PipeWire, USB Audio, HD Audio (Realtek ALC4080)
- **Bluetooth pairing**: `BT_HCIBTUSB`, `BT_HCIBTUSB_MTK`, `BT_HIDP`,
  `BT_RFCOMM`, `BT_LE_L2CAP_ECRED`, A2DP
- **Camera**: V4L2 + UVC (Razer Kiyo Pro). `RC_CORE` / `LIRC` deliberately not
  touched because `uvcvideo` may select `RC_CORE`.
- **Optical**: `ISO9660`, `UDF` (Pioneer BD-RW)
- **VMs**: `KVM_AMD`, `VIRTIO_*`, KVM userspace (ninja is a host, not a guest)
- **Storage**: NVMe, ext4, LUKS (`dm-crypt`), vfat, exfat, FUSE, overlayfs,
  NTFS3
- **RAM**: `TRANSPARENT_HUGEPAGE`, `KSM`, `LRU_GEN` (MGLRU), `ZRAM`, `ZSWAP`,
  `MEMFD_CREATE`
- **CPU**: `AMD_PSTATE`, `AMD_PMC`, `AMD_NB`, `AMD_IOMMU`, `K10TEMP`,
  `NCT6775`, `PREEMPT_DYNAMIC`, `CGROUPS`, `SCHED_AUTOGROUP`,
  `BFQ_GROUP_IOSCHED`
- **Sensors**: `SENSORS_NCT6775`, `SENSORS_K10TEMP`, `SENSORS_JC42`
  (SPD5118), `SENSORS_NVME`, `SENSORS_AMD_ENERGY`
- **I2C**: `I2C_PIIX4`, `I2C_SMBUS`, `I2C_DEV` (ddcutil + DDC/CI)
- **TPM**: `TCG_CRB` (AMD fTPM)
- **NFS client**: `NFS_FS`, `NFS_FSCACHE` (`/mnt/storage`)
- **Board**: `ASUS_WMI`, `ASUS_NB_WMI`, `ACPI_WMI` (ARGB, fan, ROG features)

Hardware reference: [hardware.md](hardware.md).

## Cascade caveats — symbols that could NOT be disabled

These entries were tried but had to be removed during iteration. The
`generate-config.pl` script bails on "repeated question" when a symbol is
`select`-ed by another enabled driver. With `ignoreConfigErrors` we can ignore
the post-resolve strict check, but the perl script's repeat-detect runs
earlier and is unaffected.

| Symbol(s)                                                                                             | Cascade source                                     |
| ----------------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| `BNX2`, `BNX2X`, `TG3`, `BNXT`                                                                        | Broadcom NICs: CNIC select chain                   |
| `CHELSIO_T1`, `T3`, `T4`                                                                              | Same CNIC chain                                    |
| `CRYPTO_TWOFISH`, `SERPENT`, `CAMELLIA`, `CAST5/6`, `ARIA`, `TEA`, `VMAC`, `WP512`, `TGR192`          | `CRYPTO_TEST` and similar self-test selectors      |
| `MHI_BUS`, `MHI_NET`                                                                                  | `ATH11K/ATH12K` (Qualcomm WiFi 6/7) chains         |
| `LIBNVDIMM`, `DAX`                                                                                    | `X86_PMEM_LEGACY` / `ACPI_NFIT` select chain       |
| `SCSI_MPT3SAS`                                                                                        | Selected by storage subsystem                      |
| `FW_LOADER_USER_HELPER`                                                                               | Selected by drivers needing user firmware fallback |
| `MEDIA_ANALOG_TV_SUPPORT`, `MEDIA_DIGITAL_TV_SUPPORT`, `MEDIA_RADIO_SUPPORT`, `MEDIA_SDR_SUPPORT`     | Selected by webcam/USB media stack                 |
| `SOUND_OSS_CORE`, `SND_OSSEMUL`, `SYSV_FS`, `NETROM`, `ROSE` (when not already declared in this list) | Various — left disabled with parent off            |

`ATA_PIIX`, `PATA_*`, several `SATA_*` — separately blocked: NixOS's standard
initrd module list (in `nixos/modules/system/boot/kernel.nix` under
`boot.initrd.includeDefaultModules`) requires these unconditionally. See
"Debugging" below.

## Debugging "Module X not found" failures

When `just build` succeeds at kernel + modules but fails at
`linux-X.Y.Z-modules-shrunk` with `modprobe: FATAL: Module X not found`, the
cause is: NixOS's initrd builder expects module X to exist, but the slim
disabled the `CONFIG_X` that produces it.

Two NixOS source files define which modules the initrd needs. To find the
offending list:

```bash
# Resolve the exact nixpkgs revision pinned by this flake:
NIXPKGS=$(nix flake metadata --json | jq -r '.locks.nodes.nixpkgs.locked | "/nix/store/\(.narHash | sub("sha256-"; ""))-source"')
# Or simpler — grep every nixpkgs source already unpacked in /nix/store:
grep -rln "MODULE_NAME_HERE" /nix/store/*-source/nixos/modules/ 2>/dev/null
```

1. **`nixos/modules/system/boot/kernel.nix`** — anchor: option name
   `boot.initrd.includeDefaultModules`. Defaults to `true`, so the
   unconditional list applies to every host. Includes SATA/PATA (`ahci`,
   `ata_piix`, `pata_marvell`, `sata_nv`, `sata_via`, `sata_sis`,
   `sata_uli`), NVMe (`nvme`), block (`sd_mod`, `sr_mod`, `mmc_block`), USB
   (`uhci_hcd`, `ehci_hcd`, `ohci_hcd`, `xhci_hcd`, `usbhid`), HID
   (`hid_generic`, `hid_apple`, `hid_logitech_*`, `hid_microsoft`,
   `hid_cherry`, `hid_corsair`, etc.).

2. **`nixos/modules/hardware/all-hardware.nix`** — anchor: gated by
   `hardware.enableAllHardware`. ninja sets `hardware.enableAllFirmware = true`
   (different option), so this file is NOT pulled in. A host that enables
   `enableAllHardware` would expand the required list significantly — re-audit
   slim if that flips.

Any `CONFIG_X` whose module name appears in either list must be kept enabled
(left out of the disable block in `kernel-slim.nix`), otherwise modules-shrunk
fails and the build aborts before producing a system.

## Updating the kernel pin

7.0.x is **not an LTS line**. When a newer release is desired, fetch the
tarball hash and update both `version` and `hash` in `kernel-slim.nix`:

```bash
nix store prefetch-file --hash-type sha256 \
  https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-X.Y.Z.tar.xz
```

NVIDIA driver rebuilds against the new kernel headers automatically on the next
switch. If a newer kernel breaks something, roll back by booting the pinned
"NixOS — Slim Kernel 7.0.10" entry in systemd-boot (its kernel+initrd live in
`/boot/EFI/pinned/` and survive `nh clean`).

## Slim metrics

| Metric                | Stock kernel | Slim kernel | Δ vs stock      |
| --------------------- | ------------ | ----------- | --------------- |
| Total config options  | 13,434       | 11,922      | −1,512 (−11.3%) |
| Built-in (`=y`)       | 2,670        | 2,319       | −351 (−13.1%)   |
| Modules (`=m`)        | 7,199        | 6,103       | −1,096 (−15.2%) |
| Enabled options total | 9,869        | 8,422       | −1,447 (−14.7%) |

Disk savings: ~30–100 MB of module storage (`DRM_AMDGPU` alone is the heaviest
single cut). RAM savings at runtime are near zero — kernel only loads modules
for hardware present.

## MT7922 incident reference (2026-05-26)

Independent of slim, ninja hit the MediaTek MT7922 BT `wmt func ctrl -22`
regression introduced in Linux 7.0.7 by commit `5c5e8c52e3ca` ("Bluetooth:
btmtk: move btusb*mtk*[setup, shutdown] to btmtk.c"). The Chris Lu autopm fix
landed in stable 7.0.8 (patchwork URL:
<https://patchew.org/linux/20241223085818.722707-1-chris.lu@mediatek.com/>),
and nixpkgs picked it up on the 7.0.10 bump. The kernel pin in
`kernel-slim.nix` is intentionally set to 7.0.10 (not 7.0.9) for this reason.
