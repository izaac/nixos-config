# Hardware Configuration - ninja

> **Last Updated**: 2026-11-07 **System**: ASUS ROG STRIX X670E-F GAMING WIFI **OS**: NixOS 26.05

---

## Documentation Links

- [Security & Hardening](security.md)
- [NVIDIA Driver Updates (windy)](nvidia-driver-updates.md)
- [Software Overview](../README.md)

---

## System Overview

| Component       | Model                                    | Notes                                        |
| --------------- | ---------------------------------------- | -------------------------------------------- |
| **Motherboard** | ASUS ROG STRIX X670E-F GAMING WIFI       | BIOS: 3304 (2025-09-19)                      |
| **CPU**         | AMD Ryzen 9 9950X3D                      | 16-Core, 32-Thread; PBO Eco 105W + Curve -15 |
| **GPU**         | Intel Arc B580 12GB (Xe2-HPG Battlemage) | PCIe 4.0 x8 card in Gen5 x16 slot, ReBAR     |
| **RAM**         | 64GB DDR5                                | 2x 32GB DIMMs (Slots 1 & 3)                  |
| **Chipset**     | AMD X670E                                | Dual chipset design                          |

---

## PCIe Slot Configuration

### Physical Slots

| Slot          | Type     | Speed    | Device         | Bandwidth                |
| ------------- | -------- | -------- | -------------- | ------------------------ |
| **PCIEX16_1** | x16      | PCIe 5.0 | Intel Arc B580 | x8 @ PCIe 4.0 (card max) |
| **PCIEX16_2** | x16 (x4) | PCIe 4.0 | Empty          | -                        |
| **PCIEX1**    | x1       | PCIe 3.0 | Empty          | -                        |

### PCIe Lane Allocation

**From CPU (28 lanes total):**

- 16 lanes -> GPU slot (PCIEX16_1) - **all 16 lanes active** - 4 lanes -> M.2_1 slot (PCIe 5.0)
- 4 lanes -> Chipset uplink
- 4 lanes -> M.2_2 slot (currently **empty** - no bifurcation)

**From Chipset:**

- M.2_3 and M.2_4 (PCIe 4.0 x4 each)
- USB controllers, SATA controllers, Ethernet

---

## CPU Power & Thermal Tuning

The 9950X3D is tuned for low heat output and quiet operation in a warm room, trading a small amount
of peak multi-core performance for much lower socket power and temperatures.

### BIOS settings (ASUS ROG STRIX X670E-F)

Set under `Ai Tweaker → Precision Boost Overdrive`:

| Setting             | Value     | Effect                                         |
| ------------------- | --------- | ---------------------------------------------- |
| **PBO Mode**        | Eco Mode  | Caps socket power (PPT) for the 105W class     |
| **Eco Mode TDP**    | 105W      | PPT ceiling ~142W (vs ~200W stock)             |
| **Curve Optimizer** | -15 (all) | All-core undervolt; cooler and slightly faster |

> The Curve Optimizer offset is a mild -15. If long stress runs or games ever crash/freeze hours in,
> back off toward -10. Validate with a sustained all-core load after any change.

### Linux-side cap (NixOS)

Independent of BIOS, NixOS caps boost frequency (the two stack):

- `hosts/ninja/performance.nix`: `scaling_max_freq = 4500000` (4.5 GHz boost cap)
- GameMode lifts the cap to the full 5.7 GHz only while a game runs
  (`hosts/ninja/configuration.nix`: `cpuBoostFreq`/`cpuBaseFreq`)
- `amd_pstate=active` (`hosts/ninja/boot.nix`)

Note: PPT/TDP and Curve Optimizer are BIOS-only on desktop AM5 - `ryzenadj` does not apply to
desktop Zen 5, so the power cap must be set in firmware.

### How the two caps interact

There are two independent ceilings. Both are active at all times, and the **lower one wins** at any
given moment:

1. **Power cap (BIOS, PPT ~142W)** - a hard wall on socket power. Under load the CPU ramps power up
   to this limit automatically, but never past it.
2. **Frequency cap (NixOS, 4.5 GHz)** - a hard wall on boost clock for normal tasks. GameMode lifts
   it to 5.7 GHz only while a game runs.

Key consequence: unlocking 5.7 GHz (GameMode) only grants _permission_ to boost. The chip reaches
5.7 GHz only if doing so fits within the ~142W power budget. That is true for light/few-threaded
work (most games), but a full all-core load cannot afford 5.7 GHz at 142W, so clocks settle lower to
stay within the power cap.

| Workload                         | Power behaviour       | Clock reached           |
| -------------------------------- | --------------------- | ----------------------- |
| Light / few threads (games)      | Well under 142W       | Near 5.7 GHz (GameMode) |
| Heavy all-core (compile, render) | Ramps up to ~142W cap | Settles ~4.5-4.7 GHz    |
| Normal desktop (browse, VM)      | Low                   | ≤ 4.5 GHz (Nix cap)     |

### Approximate all-core clock vs power cap

| PPT cap              | Sustained all-core | Multi-core perf |
| -------------------- | ------------------ | --------------- |
| Stock (~200W)        | ~5.0-5.2 GHz       | 100%            |
| **105W Eco (~142W)** | **~4.5-4.7 GHz**   | **~90-95%**     |
| 65W Eco (~88W)       | ~3.8-4.0 GHz       | ~78-82%         |

The 105W Eco point is the efficiency sweet spot: ~5-10% multi-core loss for ~30% less power and far
lower temperatures. Single/light-thread performance (games) is barely affected because it fits
inside the power budget.

### Measured (Eco 105W + Curve -15, 4.5 GHz cap)

| State         | Package power | Tctl  |
| ------------- | ------------- | ----- |
| Idle          | ~36W          | ~45°C |
| All-core load | ~80W          | ~47°C |

---

### M.2 NVMe Drives

| Slot      | Device              | Capacity | Interface       | Speed       | Usage                       | PCIe Address       |
| --------- | ------------------- | -------- | --------------- | ----------- | --------------------------- | ------------------ |
| **M.2_1** | Crucial T705        | 1TB      | PCIe 5.0 x4     | ~14 GB/s    | Root filesystem (encrypted) | `0000:02:00.0`     |
| **M.2_2** | **Empty**           | -        | PCIe 5.0 x4     | -           | **Keep empty (spare slot)** | -                  |
| **M.2_3** | Empty               | -        | PCIe 4.0 x4     | -           | From chipset                | -                  |
| **M.2_4** | **WD Black SN850X** | **4TB**  | **PCIe 4.0 x4** | **~7 GB/s** | **/mnt/data (unencrypted)** | **`0000:08:00.0`** |

> **Important**: M.2_2 slot shares PCIe lanes with PCIEX16_1 via bifurcation. When populated, the
> slot splits x8/x8. The Arc B580 is an x8 card, so its negotiated width is unaffected either way;
> **M.2_2 stays empty simply because no second boot drive is needed.**

### Current Configuration (Optimized)

**GPU at its full interface width (PCIe 4.0 x8)**

- M.2_1: Crucial T705 (PCIe 5.0 from CPU)
- M.2_2: **Empty** (no lane sharing)
- M.2_4: WD Black SN850X (PCIe 4.0 from chipset)

### Partitions

**Crucial T705 (nvme0n1):**

- `/dev/nvme0n1p1` (1GB) - EFI System Partition
- `/dev/nvme0n1p2` (930GB) - LUKS encrypted root

**WD Black SN850X (nvme1n1):**

- `/dev/nvme1n1p1` (3.6TB) - Data storage (/mnt/data)

---

## Memory Configuration

| Slot        | Module     | Capacity | Speed | Vendor                         |
| ----------- | ---------- | -------- | ----- | ------------------------------ |
| **DIMM A1** | DDR5 UDIMM | 32GB     | DDR5  | Manufacturer 0x06:0x32 rev 1.6 |
| **DIMM A2** | Empty      | -        | -     | -                              |
| **DIMM B1** | DDR5 UDIMM | 32GB     | DDR5  | Manufacturer 0x06:0x32 rev 1.6 |
| **DIMM B2** | Empty      | -        | -     | -                              |

**Total**: 64GB DDR5 (dual-channel) **Monitoring**: SPD5118 temperature sensors enabled

---

## USB Controllers

| Controller            | Location | Type | Ports | Bus |
| --------------------- | -------- | ---- | ----- | --- |
| AMD USB 3.2 (0d:00.0) | Chipset  | xHCI | 12+5  | 1-2 |
| AMD USB 3.2 (0f:00.0) | Chipset  | xHCI | 12+5  | 3-4 |
| AMD USB 3.1 (11:00.3) | CPU      | xHCI | 2+2   | 5-6 |
| AMD USB 3.1 (11:00.4) | CPU      | xHCI | 2+2   | 7-8 |
| AMD USB 2.0 (12:00.0) | CPU      | xHCI | 1     | 9   |

---

## SATA Configuration

| Port     | Controller        | Device | Status |
| -------- | ----------------- | ------ | ------ |
| SATA 0-3 | AMD 600 (0e:00.0) | None   | Unused |
| SATA 4-7 | AMD 600 (10:00.0) | None   | Unused |

---

## Network & Connectivity

| Device        | Model             | Interface | Speed   | Driver  |
| ------------- | ----------------- | --------- | ------- | ------- |
| **Ethernet**  | Intel I225-V 2.5G | eno1      | 1 Gbps  | igc     |
| **WiFi/BT**   | MediaTek MT7922   | -         | WiFi 6E | mt7921e |
| **Bluetooth** | MediaTek MT7922   | hci0      | BT 5.2  | btusb   |

---

## Graphics & Display

### Primary GPU

**Intel Arc B580 12GB (Xe2-HPG Battlemage)**

- **Architecture**: Xe2-HPG "Battlemage", 12GB GDDR6
- **PCIe**: 4.0 x8 card in the Gen5 x16 slot (negotiates at the card's full x8 width)
- **Resizable BAR**: required by the `xe` driver, enabled in BIOS
- **Video encode/decode**: AV1, HEVC and AVC hardware encode + decode via VA-API
  (`intel-media-driver`, `iHD`) and oneVPL (`vpl-gpu-rt`); used by `wf-recorder`, Chromium and
  browser video playback
- **Compute**: oneAPI / Level Zero via `intel-compute-runtime`
- **Driver**: upstream in-tree `xe` kernel driver (no out-of-tree binary driver)
- **Power**: 190W reference board TDP; no custom clock/power ceiling service (the NVIDIA
  `nvidia-lock-clocks` unit was removed with the card)

### Video Outputs

- 3x DisplayPort 2.1
- 1x HDMI 2.1

---

## Audio Devices

| Device           | Type           | Interface     | Driver        |
| ---------------- | -------------- | ------------- | ------------- |
| HDMI/DP Audio    | GPU            | PCIe          | snd_hda_intel |
| USB Audio        | Audioengine 2+ | USB (11:00.3) | snd-usb-audio |
| Realtek ALC4080  | Motherboard    | HDA           | snd_hda_intel |
| USB Headset Port | ASUS ROG Audio | USB (3-6)     | snd-usb-audio |

---

## Sensors & Monitoring

### Hardware Monitoring Chips

| Chip                      | Location             | Monitors                           | Interface |
| ------------------------- | -------------------- | ---------------------------------- | --------- |
| **NCT6796D-S/NCT6799D-R** | SuperIO (0x2e:0x290) | CPU/System temps, 7 fans, voltages | ISA       |
| **SPD5118** (0x51)        | DIMM A1              | Memory temperature                 | I2C       |
| **SPD5118** (0x53)        | DIMM B1              | Memory temperature                 | I2C       |
| **k10temp**               | CPU                  | Tctl/Tdie, Tccd1-8                 | PCI       |
| **nvme**                  | nvme0 (Crucial)      | SSD temperature                    | NVMe      |
| **nvme**                  | nvme1 (WD Black)     | SSD temperature                    | NVMe      |

### Available Sensors

```bash
# CPU Temperature
sensors k10temp-pci-00c3

# Memory Temperatures
sensors spd5118-i2c-1-51
sensors spd5118-i2c-1-53

# Motherboard Sensors (NCT6796D)
sensors nct6775-isa-0290
# - CPU Fan, CPU Optional Fan
# - Chassis Fans 1-3
# - AIO Pump, Water Pump
# - System temps, CPU voltage, etc.

# Storage Temperatures
sensors nvme-pci-0200  # Crucial T705
sensors nvme-pci-0800  # WD Black SN850X
```

---

## Peripherals

### Input Devices

| Device       | Model                          | Interface    | Port  |
| ------------ | ------------------------------ | ------------ | ----- |
| **Keyboard** | 8BitDo Retro Keyboard Receiver | USB Wireless | 3-2   |
| **Mouse**    | Razer DeathAdder V3            | USB Wired    | 3-3   |
| **Gamepad**  | 8BitDo Ultimate 2              | USB Wireless | 5-1.4 |

### Other Peripherals

| Device             | Model                 | Interface    | Port  |
| ------------------ | --------------------- | ------------ | ----- |
| **Webcam**         | Razer Kiyo Pro        | USB 3.0      | 2-2   |
| **Optical Drive**  | Pioneer BD-RW BDR-X13 | USB 3.0      | 8-2   |
| **Speakers**       | Audioengine 2+        | USB Audio    | 5-2.1 |
| **RGB Controller** | ASUS AURA LED         | USB          | 3-7   |
| **Bluetooth Hub**  | CSR8510 A10           | USB Internal | 5-2   |

---

## Power & Cooling

### Fan Configuration

| Fan Header | Device     | Control | Speed    |
| ---------- | ---------- | ------- | -------- |
| CPU_FAN    | CPU Cooler | PWM     | Variable |
| CPU_OPT    | -          | PWM     | -        |
| CHA_FAN1   | Case Fan   | PWM     | Variable |
| CHA_FAN2   | Case Fan   | PWM     | Variable |
| CHA_FAN3   | Case Fan   | PWM     | Variable |
| AIO_PUMP   | -          | PWM     | -        |
| W_PUMP+    | -          | PWM     | -        |

> **Note**: All fan curves managed by BIOS. Fan speeds visible via `nct6775` kernel module.

---

## BIOS Configuration

### Key Settings

| Setting                 | Value                 | Notes                                |
| ----------------------- | --------------------- | ------------------------------------ |
| **PCIe Link Mode**      | Auto                  | GPU at Gen4 x8 (card), M.2_1 Gen5 x4 |
| **IOMMU**               | Enabled (Passthrough) | For virtualization                   |
| **PCIe ASPM**           | Disabled              | Better latency                       |
| **AMD PSP/fTPM**        | Enabled               | TPM 2.0 via firmware                 |
| **Resizable BAR**       | Enabled               | Required by Intel Arc (`xe`)         |
| **Smart Access Memory** | Enabled               | AMD SAM                              |
| **SR-IOV**              | Enabled               | N/A for Arc B580; legacy BIOS value  |

### Boot Configuration

- **Secure Boot**: Disabled (NixOS requirement)
- **CSM**: Disabled (UEFI only)
- **Boot Mode**: UEFI
- **Fast Boot**: Disabled

---

## PCIe Device Tree

```text
00:00.0 Host bridge: AMD Raphael/Granite Ridge Root Complex
00:01.1 PCIe Root Port [GPU] x16 @ PCIe 5.0
    `-01:00.0 Intel Arc B580 (negotiates x8 @ PCIe 4.0 - card width)
       `-01:00.1 Intel Arc HDA Audio

00:01.2 PCIe Root Port [M.2_1]
    `-02:00.0 Crucial T705 NVMe (x4 @ PCIe 5.0)

00:02.1 PCIe Root Port [Chipset]
    `-03:00.0 AMD 600 Series PCIe Switch
       `-04:08.0 PCIe Switch
          `-06:00.0 PCIe Switch
             `-07:05.0 PCIe Switch
                `-09:00.0 Intel I225-V Ethernet
       |-07:0c.0 -> 0d:00.0 USB 3.2 Controller
       |-07:0d.0 -> 0e:00.0 SATA Controller (4 ports)
       |-04:0c.0 -> 0f:00.0 USB 3.2 Controller
       `-04:0d.0 -> 10:00.0 SATA Controller (4 ports)

00:02.2 PCIe Root Port [Chipset - M.2_4]
    `-08:00.0 WD Black SN850X NVMe (x4 @ PCIe 4.0)
00:08.1 PCIe Root Port [CPU USB/PSP]
    `-11:00.x Internal devices (PSP, USB 3.1 x2, CCP)

00:08.3 PCIe Root Port [CPU USB]
    `-12:00.0 USB 2.0 xHCI Controller
```

---

## Kernel Modules

### Critical Modules

```nix
boot.kernelModules = [
  "kvm-amd"           # CPU virtualization
  "nct6775"           # Motherboard sensors  Required
  "xe"                # Intel Arc GPU driver (in-tree; also loaded in initrd)
];

boot.extraModulePackages = [
  config.boot.kernelPackages.nct6775  # Out-of-tree sensor module
];
```

### Important Notes

- **nct6775** module is essential for fan monitoring and control
- Module must be loaded before ACPI WMI (motherboard-specific)
- GPU uses the upstream in-tree `xe` driver (`i915` does not bind Battlemage)

---

## Performance Tuning

### CPU

- **Governor**: `amd_pstate=active` (P-state driver)
- **Scheduler**: `scx_lavd` (BPF scheduler)
- **Preemption**: `PREEMPT_DYNAMIC=full`

### Memory

- **Transparent Hugepages**: `madvise` (on-demand)
- **ZRAM**: 64GB compressed swap (priority 5)

### Storage

- **I/O Scheduler**: `mq-deadline` (NVMe), `none` (for SSDs)
- **NVMe Features**: 32 I/O queues per drive

### GPU

- **Driver**: upstream `xe` kernel driver (in-tree, zero binary-driver maintenance)
- **ModeSetting**: built into `xe` (DRM modesetting always on)
- **Video acceleration**: VA-API via `iHD` (`LIBVA_DRIVER_NAME=iHD`), oneVPL via `vpl-gpu-rt`

---

## Configuration Optimization Notes

### Current Optimized Setup (2026-02-11)

**Storage Layout:**

- M.2_1: Crucial T705 (PCIe 5.0 from CPU)
- M.2_2: **Empty** (to avoid GPU bifurcation)
- M.2_4: WD Black SN850X (PCIe 4.0 from chipset)

**Result:**

- GPU runs at **its full x8 width** (PCIe 4.0, card maximum)
- Both NVMe drives at full speed
- No PCIe lane conflicts

### What NOT to Do

**M.2_2 shares PCIe lanes with the GPU slot** (PCIEX16_1):

- When M.2_2 is populated -> the slot bifurcates to x8/x8
- The Arc B580 is an x8 card, so it keeps its full link width either way
- Prefer M.2_3 or M.2_4 for expansion anyway (chipset-fed, zero slot games)

---

## USB Quirks

```nix
# Required quirks for specific devices. usbcore.quirks must be ONE
# comma-separated parameter: repeating it keeps only the last value.
boot.kernelParams = [
  "usbcore.quirks=2ca3:4011:g,1532:0e05:k"  # DJI Mic Mini + Razer Kiyo Pro
  "usbcore.autosuspend=-1"                  # Disable global USB autosuspend
];
```

---

## Upgrade Path

### RAM

- **Current**: 64GB (2x32GB)
- **Max**: 128GB (4x32GB DDR5)
- **Available Slots**: A2, B2

### Storage

- **M.2_2**: Available (splits GPU slot x8/x8; harmless for the x8 B580)
- **M.2_3**: Available (chipset, PCIe 4.0 x4) - **Use this for expansion**
- **SATA**: 8 ports available (unused)

### PCIe

- **PCIEX16_2**: Available (x4 @ PCIe 4.0 from chipset)
- **PCIEX1**: Available (x1 @ PCIe 3.0 from chipset)

---

## Troubleshooting

### Check GPU PCIe Link Width

```bash
# Should show: 8 (B580 is an x8 card - that is its full width)
cat /sys/bus/pci/devices/0000:01:00.0/current_link_width

# Should show: 16 (slot capability)
cat /sys/bus/pci/devices/0000:01:00.0/max_link_width
```

### Check NVMe Drives

```bash
# List NVMe devices
ls -l /sys/block/nvme*

# Check drive locations
lspci -tv | grep -i nvme
```

### Monitor Sensors

```bash
# List all sensors
sensors

# Watch temperatures in real-time
watch -n 1 sensors
```

---

## References

- [ASUS ROG STRIX X670E-F Product Page](https://rog.asus.com/motherboards/rog-strix/rog-strix-x670e-f-gaming-wifi-model/)
- [AMD Ryzen 9 9950X3D Specifications](https://www.amd.com/en/products/processors/desktops/ryzen/9000-series/amd-ryzen-9-9950x3d.html)
- [Intel Arc B580 Specifications](https://www.intel.com/content/www/us/en/products/sku/239790/intel-arc-b580-graphics-card/specifications.html)
- [NixOS Hardware Configuration](https://wiki.nixos.org/wiki/Hardware/Asus)

---

_Generated from system introspection on 2026-02-11_ _Last hardware change (2026-11-07): swapped the
RTX 5060 Ti for an Intel Arc B580 (in-tree `xe` driver, AV1/HEVC/AVC hardware encode)_

---

## nixos-hardware Modules Reference

This project uses the [NixOS/nixos-hardware](https://github.com/NixOS/nixos-hardware) repository for
hardware-specific configuration modules. Each host imports the modules relevant to its platform.

### ninja (Desktop: AMD Ryzen 9 9950X3D + Intel Arc B580)

Located in `hosts/ninja/configuration.nix`:

| Module                  | Purpose                          | Why Needed                                                                                                                                                              |
| ----------------------- | -------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `common-cpu-amd-pstate` | AMD P-State driver configuration | Enables `amd_pstate=active` for modern AMD CPUs (Zen 2+). Provides better performance/power than acpi-cpufreq. Required for 9950X3D.                                    |
| `common-gpu-intel`      | Intel GPU (Arc discrete) config  | Declares `hardware.intelgpu`: in-tree `xe` driver loaded in the initrd, `intel-media-driver` (iHD) VA-API, `intel-compute-runtime` + `vpl-gpu-rt` acceleration stack.   |
| `common-pc-ssd`         | SSD/NVMe optimizations           | Enables TRIM via `fstrim.timer`, sets `nvme_core.default_ps_max_latency_us=0` for lowest latency. Benefits both Crucial T705 (PCIe 5.0) and WD Black SN850X (PCIe 4.0). |

### windy (Laptop: Intel i9-11980HK + NVIDIA RTX 3080 Mobile Prime Offload)

Located in `hosts/windy/configuration.nix`:

| Module              | Purpose                              | Why Needed                                                                                                                                |
| ------------------- | ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------- |
| `common-cpu-intel`  | Intel CPU power/performance defaults | Sets `intel_pstate=active`, enables HWP, configures thermald defaults. Required for 11th gen Intel mobile.                                |
| `common-gpu-nvidia` | NVIDIA Prime offload (laptop) config | Configures Prime render offload: iGPU drives display, dGPU used on-demand via `__NV_PRIME_RENDER_OFFLOAD=1`. Sets `nvidia-drm.modeset=1`. |
| `common-pc-laptop`  | Laptop-specific power/ACPI defaults  | Enables laptop-mode tools, configures lid switch, battery thresholds, ACPI battery module, fn keys.                                       |
| `common-pc-ssd`     | SSD/NVMe optimizations               | Same as ninja: TRIM timer, NVMe latency tuning. Benefits laptop NVMe drive.                                                               |

### plex (Headless Server: Intel N100 Mini PC)

Located in `hosts/plex/configuration.nix`:

| Module             | Purpose                              | Why Needed                                                                   |
| ------------------ | ------------------------------------ | ---------------------------------------------------------------------------- |
| `common-cpu-intel` | Intel CPU power/performance defaults | Sets `intel_pstate=active`, enables HWP. Required for the Alder Lake-N N100. |
| `common-pc-ssd`    | SSD/NVMe optimizations               | Same as ninja: TRIM timer, NVMe latency tuning. Benefits the SATA SSD.       |

No GPU module: the N100 iGPU needs no nixos-hardware profile; QuickSync is wired up directly via
`hardware.graphics.extraPackages` (`intel-media-driver`, `vpl-gpu-rt`). See [plex](plex.md).

### canoe / canoe-niri (ISO Builds)

These are minimal live ISO configurations (`hosts/canoe/minimal.nix`, `hosts/canoe/niri.nix`). They
**do not** import nixos-hardware modules because:

- ISOs must boot on arbitrary hardware
- nixos-hardware modules are machine-specific and would break portability
- The installer kernel already includes all necessary drivers

Both ISOs ship sshd with pre-authorized keys and passwordless `sudo-rs`; see
[disko-rebuild](disko-rebuild.md#remote-access-ssh) for remote access details.

### Module Selection Guide

When adding a new host (see [Adding a New Host](adding-a-host.md)):

1. Create `hosts/<name>/system.nix` with the system type string
2. **Identify CPU vendor**: AMD → `common-cpu-amd-pstate`, Intel → `common-cpu-intel`
3. **Identify GPU setup**:
   - NVIDIA desktop (no iGPU) → `common-gpu-nvidia-nonprime`
   - NVIDIA laptop with Prime offload → `common-gpu-nvidia`
   - AMD GPU → `common-gpu-amd` (if available)
   - Intel Arc discrete (Xe2) → `common-gpu-intel` with `hardware.intelgpu.driver = "xe"`
   - Intel iGPU only → no GPU module needed
4. **Form factor**: Laptop → `common-pc-laptop`, Desktop → skip
5. **Storage**: NVMe/SSD → `common-pc-ssd` (almost always)

### Why Not Use `nixos-hardware.auto`?

The `nixos-hardware.auto` module attempts to auto-detect hardware and apply matching modules. We
**don't use it** because:

- Auto-detection can misidentify hardware (e.g., desktop with iGPU detected as laptop)
- Explicit imports are auditable and predictable
- Each module's purpose is clear in the configuration
- Easier to debug when something breaks

---

_Generated from system introspection on 2026-02-11_ _Last hardware change (2026-11-07): swapped the
RTX 5060 Ti for an Intel Arc B580 (in-tree `xe` driver, AV1/HEVC/AVC hardware encode)_
