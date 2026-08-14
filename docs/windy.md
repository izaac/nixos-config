# Hardware Configuration - windy

> **Last Updated**: 2026-02-19
> **System**: GIGABYTE AERO 15 YD
> **OS**: NixOS 25.11

---

## System Overview

| Component        | Model                                       | Notes                                  |
| ---------------- | ------------------------------------------- | -------------------------------------- |
| **Laptop**       | GIGABYTE AERO 15 YD                         | BIOS: FB08 (2022-03-11)                |
| **CPU**          | Intel Core i9-11980HK                       | 8-Core, 16-Thread @ 2.60GHz            |
| **GPU (Hybrid)** | NVIDIA RTX 3080 Mobile + Intel UHD Graphics | NVIDIA Prime Offload enabled           |
| **RAM**          | 64GB DDR4                                   | 2x 32GB DIMMs                          |
| **Display**      | 15.6" OLED                                  | Backlight fix: `acpi_backlight=native` |

---

## Storage Configuration

### M.2 NVMe Drives

| Slot      | Device              | Capacity | Usage                            |
| --------- | ------------------- | -------- | -------------------------------- |
| **nvme0** | Phison/Gigabyte OEM | 1TB      | Root filesystem (LUKS encrypted) |
| **nvme1** | Expansion Drive     | 2TB      | Secondary Storage (/mnt/data)    |

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
- **KMS**: disabled (`nvidia-drm modeset=0`). The dGPU exposes only its render
  node, so the compositor cannot claim it. See below.

#### Keeping the dGPU asleep

The card idles in D3cold and only wakes when something opens its render node.
Getting there took two separate fixes, because two different things were holding
it awake for the entire session. Symptom in both cases:
`runtime_suspended_time` stuck at `0` while the card burned roughly 12.5 W in
P8 at 0% utilisation, over half the machine's idle draw.

1. **`nvidia-drm modeset=0`** (`hosts/windy/configuration.nix`). With KMS on,
   the dGPU registers `/dev/dri/card0` on the login seat and niri opens it at
   startup even though it composites on the Intel iGPU. With KMS off, niri
   still probes the node but bounces off it, which is the intended outcome:

   ```text
   niri: using as the render node: renderD128   (Intel)
   niri: adding device: /dev/dri/card0
   niri: error adding device ... (os error 95)  <- rejected, expected
   ```

   An earlier attempt (541facc) stripped the seat tags with a udev rule
   instead; that left niri unable to start at all. Overriding the module
   parameter via `hardware.nvidia.moduleParams` is the supported knob and
   leaves the seat untouched.

2. **Hiding the NVIDIA Vulkan and EGL drivers from ashell**
   (`home/ashell.nix`). This was the real culprit and it outlived the first
   fix. ashell draws through iced/wgpu, which enumerates every adapter at
   startup and then holds `/dev/nvidia0`, `/dev/nvidiactl`,
   `/dev/nvidia-modeset` and `renderD129` open for the life of the process.
   That single reference is enough to pin the card out of runtime D3. The
   session wrapper now exports `VK_LOADER_DRIVERS_DISABLE`,
   `__EGL_VENDOR_LIBRARY_FILENAMES` and `__GLX_VENDOR_LIBRARY_NAME` for that
   process only. Applied on hybrid hosts only: ninja is NVIDIA-only and would
   be left with no renderer.

Result: idle draw dropped from 20-23 W to 14-18 W.

The GPU's HDMI audio function (`0000:01:00.1`, `snd_hda_intel`) is a third
potential blocker: a multi-function PCI device cannot reach D3cold until every
function is suspended. TLP's `SOUND_POWER_SAVE_ON_BAT = 1` already releases it
on battery. It stays awake on AC by design, where idle draw does not matter.

**Trade-off**: the external HDMI and DisplayPort outputs are wired to the dGPU
and need its KMS node, so they stay dark. PRIME render offload is unaffected
because it runs off the render node.

#### Checking the GPU

Read the runtime state from sysfs. This does **not** wake the card:

```bash
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status   # suspended | active
cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_suspended_time
```

`suspended_time` climbing while idle is the health check. If it stays at `0`,
something is holding the card open again. Find the holder with:

```bash
sudo bash -c 'shopt -s nullglob
for pid in /proc/[0-9]*; do
  for fd in "$pid"/fd/*; do
    t=$(readlink "$fd" 2>/dev/null) || continue
    case "$t" in /dev/nvidia*|/dev/dri/renderD129|/dev/dri/card0)
      printf "%-16s -> %s\n" "$(cat $pid/comm)" "$t";;
    esac
  done
done | sort -u'
```

Note this must run under bash. The interactive shell here is zsh, where an
unmatched glob aborts the loop and the scan silently reports nothing.

**`nvidia-smi` wakes the GPU**, so it is not a way to check whether the card is
asleep. It is the right tool once the card is already in use; the first reading
after a wake is taken mid-transition and is meaningless (values like 752 W).

#### Using the GPU

Games and anything else that wants discrete graphics:

```bash
nvidia-offload <command>
```

In Steam, set the launch options to `nvidia-offload %command%`. The wrapper sets
`__NV_PRIME_RENDER_OFFLOAD=1`, `__GLX_VENDOR_LIBRARY_NAME=nvidia` and
`__VK_LAYER_NV_optimus=NVIDIA_only`, the card wakes on first use and idles back
down when the process exits.

Video playback should **not** be offloaded. The Intel iGPU has a fixed-function
decoder and mpv already uses it (`hwdec = "auto-safe"` in `home/mpv.nix`).
Waking a 12 W GPU to decode a film costs far more power than the iGPU path and
gains nothing.

Firefox had to be told this explicitly, twice. It decodes in a separate RDD
process, where VA-API takes its DRM fd from `DMABufDevice`, which reads
`MOZ_DRM_DEVICE` first and otherwise falls back to whichever device the glxtest
probe reported. Setting that variable moved decoding to the iGPU, but the RDD
process still loaded `libEGL_nvidia` and held `/dev/nvidia0`, `/dev/nvidiactl`
and the dGPU render node open, because Firefox's EGL device display reads
`gfxVars::DrmRenderDevice()` directly and ignores `MOZ_DRM_DEVICE`.

Those leftover handles cost no power, the card still reached D3cold, but they
break system suspend. See
[Suspend and the discrete GPU](#suspend-and-the-discrete-gpu) below.

`home/firefox.nix` therefore wraps the browser with `MOZ_DRM_DEVICE` plus
`__EGL_VENDOR_LIBRARY_FILENAMES`, `__GLX_VENDOR_LIBRARY_NAME` and
`VK_LOADER_DRIVERS_DISABLE`, leaving it no NVIDIA driver to open. The render
node is derived from `hardware.nvidia.prime.intelBusId` and the whole wrapper is
applied only where PRIME offload is enabled, so ninja keeps stock Firefox. The
last three are deliberately set on the wrapper rather than in
`home.sessionVariables`: they are not Firefox-specific, and session-wide they
would strip the dGPU from games too, breaking `nvidia-offload`.

Symptom to watch for: the `RDD Process` appearing in the holder scan above.

### Suspend and the discrete GPU

Resuming from suspend while any process holds the dGPU open fails NVIDIA's GSP
firmware boot and leaves the card unusable until reboot:

```text
NVRM: gpuPowerManagementResume: GSP boot failed at resume (bootMode 0x1): 0x62
NVRM: Xid (PCI:0000:01:00): 154, GPU recovery action changed to 0x1 (GPU Reset Required)
WARNING: nvidia/nv.c:4564 at nv_restore_user_channels
```

`nvidia-smi` then reports `[GPU requires reset]` and nonsense values such as
752 W. Confirmed by testing both cases on driver 595.71.05: suspending with the
card idle resumes cleanly, suspending with Firefox running reproduces the
failure every time. Note the card does not need to be _awake_ for this; it was
in D3cold with `runtime_usage=0` both times, merely holding open file
descriptors was enough.

This is why the Firefox wrapper matters beyond power: with nothing holding the
dGPU, suspend and resume are reliable. If a future application starts opening
the NVIDIA nodes, expect this failure to come back, and check the holder scan
above before blaming the driver.

### Display Optimizations

- **Kernel Param**: `acpi_backlight=native` (Restores GNOME brightness slider).
- **Renderer**: `GSK_RENDERER=ngl` (Fixes OpenGL initialization on some apps).

---

## Network & Connectivity

| Device        | Model                   | Interface | Driver  |
| ------------- | ----------------------- | --------- | ------- |
| **Ethernet**  | Realtek RTL8125B 2.5GbE | enp46s0   | r8169   |
| **WiFi**      | Intel Wi-Fi 6 AX200     | wlp48s0   | iwlwifi |
| **Bluetooth** | Intel AX200             | hci0      | btusb   |

---

## Audio

- **Server**: Pipewire (with PulseAudio emulation)
- **Hardware**: Realtek ALC255 (HDA Intel PCH)

---

## Power Management

windy is tuned as the inverse of ninja. ninja compiles a bespoke low-latency
kernel and boots it `preempt=full`; windy stays on the cached
`linuxPackages_latest` and trades responsiveness for idle power. A
`structuredExtraConfig` would defeat the binary cache and turn every kernel bump
into a multi-hour local compile on a laptop with turbo disabled, costing far more
energy than the config could save.

- **TLP**: Enabled. Governor `powersave` on both AC and battery, turbo off,
  sustained load capped at 80% (AC) / 60% (battery). Runtime PM set to `auto`,
  PCIe ASPM `powersupersave` on battery, USB autosuspend on, Wi-Fi power save on
  battery, audio codec power save, SATA `min_power`, platform profile
  `low-power`. Charge thresholds 75-80% for battery longevity.
- **Thermald**: Enabled (Intel-specific thermal monitoring)
- **ZRAM**: 64GB Compressed Swap (100% memory priority)
- **Kernel parameters**: `preempt=voluntary`, `pcie_aspm.policy=powersupersave`,
  `nvme.noacpi=1`, `nvidia-drm modeset=0` (see
  [Keeping the dGPU asleep](#keeping-the-dgpu-asleep)). USB autosuspend is left
  at the kernel default; ninja opts out of it for input latency in
  `hosts/ninja/performance.nix`.
- **Sysctl**: `vm.laptop_mode=5`, dirty writeback and expiry stretched to 60s so
  the disk batches flushes, `kernel.nmi_watchdog=0`.

### Deliberately not installed

Each of these ran a daemon that polls or holds hardware awake, so they are off
on windy and live on ninja instead:

| Dropped                   | Why                                                           |
| ------------------------- | ------------------------------------------------------------- |
| Podman / docker shim      | Also removes distrobox, quickemu and the NVIDIA CDI generator |
| CUPS, cups-browsed, avahi | Both browse the network continuously to find printers         |
| `scx_lavd`                | Latency scheduler that keeps cores awake; TLP owns power here |

Tailscale is enabled: `tailscaled` is event-driven and idles cheaply.

---

## Troubleshooting & Fixes

### Slow Boot Fix (2026-02-19)

- **Issue**: 90s hang during boot ("Start job is running for /dev/mapper/luks...").
- **Cause**: Encrypted swap partition not in initrd and failing to decrypt.
- **Fix**: Removed physical swap partition, extended root, and switched to ZRAM.

### Missing Brightness Slider

- **Fix**: Re-added `acpi_backlight=native` to `boot.kernelParams`.

---

_Generated from system introspection on 2026-02-19_
