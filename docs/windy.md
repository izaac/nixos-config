# Hardware Configuration - windy

> **Last Updated**: 2026-02-19
> **System**: GIGABYTE AERO 15 YD
> **OS**: NixOS 25.11

---

## System Overview

| Component | Model | Notes |
|-----------|-------|-------|
| **Laptop** | GIGABYTE AERO 15 YD | BIOS: FB08 (2022-03-11) |
| **CPU** | Intel Core i9-11980HK | 8-Core, 16-Thread @ 2.60GHz |
| **GPU (Hybrid)** | NVIDIA RTX 3080 Mobile + Intel UHD Graphics | NVIDIA Prime Offload enabled |
| **RAM** | 64GB DDR4 | 2x 32GB DIMMs |
| **Display** | 15.6" OLED | Backlight fix: `acpi_backlight=vendor` |

---

## Storage Configuration

### M.2 NVMe Drives

| Slot | Device | Capacity | Usage |
|------|--------|----------|-------|
| **nvme0** | Phison/Gigabyte OEM | 1TB | Root filesystem (LUKS encrypted) |
| **nvme1** | Expansion Drive | 2TB | Secondary Storage (/mnt/data) |

### Partition Layout (Post-Cleanup)

**Main Drive (nvme0n1):**
- `/dev/nvme0n1p1` - EFI System Partition (/boot)
- `/dev/nvme0n1p2` - LUKS Encrypted Root (Extended to fill disk)
- **Note**: Physical swap partition (p3) removed in favor of ZRAM + Root Swapfile.

---

## Graphics & Display

### NVIDIA RTX 3080 Mobile
- **Driver**: NVIDIA Open Kernel Module (Stable)
- **Mode**: Prime Offload (On-demand)
- **Power Management**: `finegrained` enabled for battery life.

### Display Optimizations
- **Kernel Param**: `acpi_backlight=vendor` (Restores GNOME brightness slider).
- **Renderer**: `GSK_RENDERER=ngl` (Fixes OpenGL initialization on some apps).

---

## Network & Connectivity

| Device | Model | Interface | Driver |
|--------|-------|-----------|--------|
| **Ethernet** | Realtek RTL8125B 2.5GbE | enp46s0 | r8169 |
| **WiFi** | Intel Wi-Fi 6 AX200 | wlp48s0 | iwlwifi |
| **Bluetooth** | Intel AX200 | hci0 | btusb |

---

## Audio

- **Server**: Pipewire (with PulseAudio emulation)
- **Backend**: `media.cubeb.backend = pulse` (Firefox optimization)
- **Hardware**: Realtek ALC255 (HDA Intel PCH)

---

## Power Management

- **TLP**: Enabled (Optimized for Intel performance/powersave switching)
- **Thermald**: Enabled (Intel-specific thermal monitoring)
- **ZRAM**: 64GB Compressed Swap (100% memory priority)

---

## Troubleshooting & Fixes

### Slow Boot Fix (2026-02-19)
- **Issue**: 90s hang during boot ("Start job is running for /dev/mapper/luks...").
- **Cause**: Encrypted swap partition not in initrd and failing to decrypt.
- **Fix**: Removed physical swap partition, extended root, and switched to ZRAM.

### Missing Brightness Slider
- **Fix**: Re-added `acpi_backlight=vendor` to `boot.kernelParams`.

---

*Generated from system introspection on 2026-02-19*
