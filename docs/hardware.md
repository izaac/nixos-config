# Hardware Configuration - ninja

> **Last Updated**: 2026-02-11
> **System**: ASUS ROG STRIX X670E-F GAMING WIFI
> **OS**: NixOS 25.11

---

## System Overview

| Component | Model | Notes |
|-----------|-------|-------|
| **Motherboard** | ASUS ROG STRIX X670E-F GAMING WIFI | BIOS: 3304 (2025-09-19) |
| **CPU** | AMD Ryzen 9 9950X3D | 16-Core, 32-Thread @ 4.3 GHz |
| **GPU** | NVIDIA GeForce RTX 5070 Ti (PNY) | PCIe 5.0 x16 @ **full x16 speed** |
| **RAM** | 64GB DDR5 | 2x 32GB DIMMs (Slots 1 & 3) |
| **Chipset** | AMD X670E | Dual chipset design |

---

## PCIe Slot Configuration

### Physical Slots

| Slot | Type | Speed | Device | Bandwidth |
|------|------|-------|--------|-----------|
| **PCIEX16_1** | x16 | PCIe 5.0 | NVIDIA RTX 5070 Ti | **256 GB/s** (full x16) ✅ |
| **PCIEX16_2** | x16 (x4) | PCIe 4.0 | Empty | - |
| **PCIEX1** | x1 | PCIe 3.0 | Empty | - |

### PCIe Lane Allocation

**From CPU (28 lanes total):**
- 16 lanes → GPU slot (PCIEX16_1) - **all 16 lanes active** - 4 lanes → M.2_1 slot (PCIe 5.0)
- 4 lanes → Chipset uplink
- 4 lanes → M.2_2 slot (currently **empty** - no bifurcation)

**From Chipset:**
- M.2_3 and M.2_4 (PCIe 4.0 x4 each)
- USB controllers, SATA controllers, Ethernet

---

## Storage Configuration

### M.2 NVMe Drives

| Slot | Device | Capacity | Interface | Speed | Usage | PCIe Address |
|------|--------|----------|-----------|-------|-------|--------------|
| **M.2_1** | Crucial T705 | 1TB | PCIe 5.0 x4 | ~14 GB/s | Root filesystem (encrypted) | `0000:02:00.0` |
| **M.2_2** | **Empty** | - | PCIe 5.0 x4 | - |  **Keep empty for GPU x16** | - |
| **M.2_3** | Empty | - | PCIe 4.0 x4 | - | From chipset | - |
| **M.2_4** | **WD Black SN850X** | **4TB** | **PCIe 4.0 x4** | **~7 GB/s** | **/mnt/storage (unencrypted)** | **`0000:08:00.0`** ✅ |

> **Important**: M.2_2 slot shares PCIe lanes with PCIEX16_1 via bifurcation. When populated, GPU drops from x16 to x8 mode. **Currently M.2_2 is empty, so GPU runs at full x16 speed.**

### Current Configuration (Optimized)

✅ **GPU at full x16 bandwidth (256 GB/s)**
- M.2_1: Crucial T705 (PCIe 5.0 from CPU)
- M.2_2: **Empty** (no lane sharing)
- M.2_4: WD Black SN850X (PCIe 4.0 from chipset)

### Partitions

**Crucial T705 (nvme0n1):**
- `/dev/nvme0n1p1` (1GB) - EFI System Partition
- `/dev/nvme0n1p2` (930GB) - LUKS encrypted root

**WD Black SN850X (nvme1n1):**
- `/dev/nvme1n1p1` (3.6TB) - Data storage

---

## Memory Configuration

| Slot | Module | Capacity | Speed | Vendor |
|------|--------|----------|-------|--------|
| **DIMM A1** | DDR5 UDIMM | 32GB | DDR5 | Manufacturer 0x06:0x32 rev 1.6 |
| **DIMM A2** | Empty | - | - | - |
| **DIMM B1** | DDR5 UDIMM | 32GB | DDR5 | Manufacturer 0x06:0x32 rev 1.6 |
| **DIMM B2** | Empty | - | - | - |

**Total**: 64GB DDR5 (dual-channel)
**Monitoring**: SPD5118 temperature sensors enabled

---

## USB Controllers

| Controller | Location | Type | Ports | Bus |
|------------|----------|------|-------|-----|
| AMD USB 3.2 (0d:00.0) | Chipset | xHCI | 12+5 | 1-2 |
| AMD USB 3.2 (0f:00.0) | Chipset | xHCI | 12+5 | 3-4 |
| AMD USB 3.1 (11:00.3) | CPU | xHCI | 2+2 | 5-6 |
| AMD USB 3.1 (11:00.4) | CPU | xHCI | 2+2 | 7-8 |
| AMD USB 2.0 (12:00.0) | CPU | xHCI | 1 | 9 |

---

## SATA Configuration

| Port | Controller | Device | Status |
|------|------------|--------|--------|
| SATA 0-3 | AMD 600 (0e:00.0) | None | Unused |
| SATA 4-7 | AMD 600 (10:00.0) | None | Unused |

---

## Network & Connectivity

| Device | Model | Interface | Speed | Driver |
|--------|-------|-----------|-------|--------|
| **Ethernet** | Intel I225-V 2.5G | eno1 | 1 Gbps | igc |
| **WiFi/BT** | MediaTek MT7922 | - | WiFi 6E | mt7921e |
| **Bluetooth** | MediaTek MT7922 | hci0 | BT 5.2 | btusb |

---

## Graphics & Display

### Primary GPU

**NVIDIA GeForce RTX 5070 Ti**
- **Model**: GB203 (rev a1)
- **Vendor**: PNY (Device ID: 196e:143c)
- **PCIe**: 5.0 x16 @ **full x16 speed** (256 GB/s) - **VRAM**: 16GB GDDR7
- **Driver**: NVIDIA Open Kernel Module 590.48.01
- **Features**:
  - SR-IOV capable (1 VF supported)
  - VF BAR sizes: 256KB, 256MB, 32MB
  - HDMI/DisplayPort audio (HDA 10de:22e9)

### Video Outputs

- 3x DisplayPort 2.1
- 1x HDMI 2.1

---

## Audio Devices

| Device | Type | Interface | Driver |
|--------|------|-----------|--------|
| HDMI/DP Audio | GPU | PCIe | snd_hda_intel |
| USB Audio | Audioengine 2+ | USB (11:00.3) | snd-usb-audio |
| Realtek ALC4080 | Motherboard | HDA | snd_hda_intel |
| USB Headset Port | ASUS ROG Audio | USB (3-6) | snd-usb-audio |

---

## Sensors & Monitoring

### Hardware Monitoring Chips

| Chip | Location | Monitors | Interface |
|------|----------|----------|-----------|
| **NCT6796D-S/NCT6799D-R** | SuperIO (0x2e:0x290) | CPU/System temps, 7 fans, voltages | ISA |
| **SPD5118** (0x51) | DIMM A1 | Memory temperature | I2C |
| **SPD5118** (0x53) | DIMM B1 | Memory temperature | I2C |
| **k10temp** | CPU | Tctl/Tdie, Tccd1-8 | PCI |
| **nvme** | nvme0 (Crucial) | SSD temperature | NVMe |
| **nvme** | nvme1 (WD Black) | SSD temperature | NVMe |

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

| Device | Model | Interface | Port |
|--------|-------|-----------|------|
| **Keyboard** | 8BitDo Retro Keyboard Receiver | USB Wireless | 3-2 |
| **Mouse** | Razer DeathAdder V3 | USB Wired | 3-3 |
| **Gamepad** | 8BitDo Ultimate 2 | USB Wireless | 5-1.4 |

### Other Peripherals

| Device | Model | Interface | Port |
|--------|-------|-----------|------|
| **Webcam** | Razer Kiyo Pro | USB 3.0 | 2-2 |
| **Optical Drive** | Pioneer BD-RW BDR-X13 | USB 3.0 | 8-2 |
| **Speakers** | Audioengine 2+ | USB Audio | 5-2.1 |
| **RGB Controller** | ASUS AURA LED | USB | 3-7 |
| **Bluetooth Hub** | CSR8510 A10 | USB Internal | 5-2 |

---

## Power & Cooling

### Fan Configuration

| Fan Header | Device | Control | Speed |
|------------|--------|---------|-------|
| CPU_FAN | CPU Cooler | PWM | Variable |
| CPU_OPT | - | PWM | - |
| CHA_FAN1 | Case Fan | PWM | Variable |
| CHA_FAN2 | Case Fan | PWM | Variable |
| CHA_FAN3 | Case Fan | PWM | Variable |
| AIO_PUMP | - | PWM | - |
| W_PUMP+ | - | PWM | - |

> **Note**: All fan curves managed by BIOS. Fan speeds visible via `nct6775` kernel module.

---

## BIOS Configuration

### Key Settings

| Setting | Value | Notes |
|---------|-------|-------|
| **PCIe Link Mode** | Auto | GPU at Gen 5 x16, M.2_1 at Gen 5 x4 |
| **IOMMU** | Enabled (Passthrough) | For virtualization |
| **PCIe ASPM** | Disabled | Better latency |
| **AMD PSP/fTPM** | Enabled | TPM 2.0 via firmware |
| **Resizable BAR** | Enabled | For GPU performance |
| **Smart Access Memory** | Enabled | AMD SAM |
| **SR-IOV** | Enabled | GPU virtualization support |

### Boot Configuration

- **Secure Boot**: Disabled (NixOS requirement)
- **CSM**: Disabled (UEFI only)
- **Boot Mode**: UEFI
- **Fast Boot**: Disabled

---

## PCIe Device Tree

```
00:00.0 Host bridge: AMD Raphael/Granite Ridge Root Complex
00:01.1 PCIe Root Port [GPU] ✅ x16 @ PCIe 5.0
  └─01:00.0 NVIDIA RTX 5070 Ti (full x16 bandwidth)
     └─01:00.1 NVIDIA HDA Audio

00:01.2 PCIe Root Port [M.2_1]
  └─02:00.0 Crucial T705 NVMe (x4 @ PCIe 5.0)

00:02.1 PCIe Root Port [Chipset]
  └─03:00.0 AMD 600 Series PCIe Switch
     └─04:08.0 PCIe Switch
        └─06:00.0 PCIe Switch
           └─07:05.0 PCIe Switch
              └─09:00.0 Intel I225-V Ethernet
     ├─07:0c.0 → 0d:00.0 USB 3.2 Controller
     ├─07:0d.0 → 0e:00.0 SATA Controller (4 ports)
     ├─04:0c.0 → 0f:00.0 USB 3.2 Controller
     └─04:0d.0 → 10:00.0 SATA Controller (4 ports)

00:02.2 PCIe Root Port [Chipset - M.2_4]
  └─08:00.0 WD Black SN850X NVMe (x4 @ PCIe 4.0) 
00:08.1 PCIe Root Port [CPU USB/PSP]
  └─11:00.x Internal devices (PSP, USB 3.1 x2, CCP)

00:08.3 PCIe Root Port [CPU USB]
  └─12:00.0 USB 2.0 xHCI Controller
```

---

## Kernel Modules

### Critical Modules

```nix
boot.kernelModules = [
  "kvm-amd"           # CPU virtualization
  "nct6775"           # Motherboard sensors  Required
  "nvidia"            # GPU driver
  "nvidia_modeset"
  "nvidia_uvm"
  "nvidia_drm"
];

boot.extraModulePackages = [
  config.boot.kernelPackages.nct6775  # Out-of-tree sensor module
];
```

### Important Notes

- **nct6775** module is essential for fan monitoring and control
- Module must be loaded before ACPI WMI (motherboard-specific)
- GPU uses open-source NVIDIA kernel module (590.48.01)

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

- **Driver**: Open kernel module (better performance)
- **ModeSetting**: Enabled (`nvidia-drm.modeset=1`)
- **Framebuffer**: Native (`nvidia-drm.fbdev=1`)

---

## Configuration Optimization Notes

### ✅ Current Optimized Setup (2026-02-11)

**Storage Layout:**
- M.2_1: Crucial T705 (PCIe 5.0 from CPU)
- M.2_2: **Empty** (to avoid GPU bifurcation)
- M.2_4: WD Black SN850X (PCIe 4.0 from chipset)

**Result:**
- GPU runs at **full x16 speed** (256 GB/s bandwidth)
- Both NVMe drives at full speed
- No PCIe lane conflicts

###  What NOT to Do

**Don't populate M.2_2 slot** unless you're willing to sacrifice GPU performance:
- M.2_2 shares PCIe lanes with GPU slot (PCIEX16_1)
- When M.2_2 is populated → GPU drops from x16 to x8 (50% bandwidth loss)
- Use M.2_3 or M.2_4 instead (chipset-fed, no GPU impact)

---

## USB Quirks

```nix
# Required quirks for specific devices
boot.kernelParams = [
  "usbcore.quirks=2ca3:4011:g"  # 8BitDo controller autosuspend disable
  "usbcore.quirks=1532:0e05:k"  # Razer Kiyo Pro keep-alive
  "usbcore.autosuspend=-1"      # Disable global USB autosuspend
];
```

---

## Upgrade Path

### RAM

- **Current**: 64GB (2x32GB)
- **Max**: 128GB (4x32GB DDR5)
- **Available Slots**: A2, B2

### Storage

- **M.2_2**: Available ( avoid - causes GPU x8 mode)
- **M.2_3**: Available (chipset, PCIe 4.0 x4) - **Use this for expansion**
- **SATA**: 8 ports available (unused)

### PCIe

- **PCIEX16_2**: Available (x4 @ PCIe 4.0 from chipset)
- **PCIEX1**: Available (x1 @ PCIe 3.0 from chipset)

---

## Troubleshooting

### Check GPU PCIe Link Width

```bash
# Should show: 16
cat /sys/bus/pci/devices/0000:01:00.0/current_link_width

# Should show: 16
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
- [NVIDIA RTX 5070 Ti Specifications](https://www.nvidia.com/en-us/geforce/graphics-cards/50-series/rtx-5070-ti-5070/)
- [NixOS Hardware Configuration](https://nixos.wiki/wiki/Laptops/ASUS)

---

*Generated from system introspection on 2026-02-11*
*Last hardware change: Moved WD Black SN850X from M.2_2 to M.2_4 for full GPU x16 bandwidth*
