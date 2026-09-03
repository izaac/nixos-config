# Hardware Configuration - plex

> **Last Updated**: 2026-08-25 **System**: PELADN Intel N100 Mini PC **OS**: NixOS 26.05

---

## System Overview

| Component   | Model                             | Notes                                        |
| ----------- | --------------------------------- | -------------------------------------------- |
| **Mini PC** | PELADN (Intel N100)               | Headless server, wired ethernet only         |
| **CPU**     | Intel N100 (Alder Lake-N)         | 4-Core, 4-Thread, up to 3.4 GHz, low TDP     |
| **GPU**     | Intel UHD Graphics (Alder Lake-N) | `8086:46d1`, QuickSync transcoding for Plex  |
| **RAM**     | 8GB                               | Single stick; ZRAM swap sized to match       |
| **Storage** | PELADN 256GB SATA SSD             | `/dev/sda`, unencrypted ext4 via disko       |
| **Role**    | Plex media server + home server   | Media served from an encrypted rclone remote |

---

## Storage Configuration

### Partition Layout (disko)

**PELADN 256GB SATA SSD (`/dev/sda`):**

- `/dev/sda1` (1G) - EFI System Partition (`/boot`, fmask/dmask 0077)
- `/dev/sda2` (237.5G) - Root filesystem, ext4 with `noatime,nodiratime,lazytime,commit=60`

No LUKS on this host. No disk swap partition; ZRAM provides swap (see
`modules/core/performance.nix`).

### Media storage (rclone)

Media lives on a crypt remote (`ul-crypt:`) mounted at `/srv/media` by the `rclone-ul-crypt.service`
unit defined in `hosts/plex/configuration.nix`:

- Mount options:
  `--allow-other --vfs-cache-mode full --vfs-cache-max-size 50G --vfs-cache-max-age 168h --buffer-size 64M`
- Runs as `izaac`, `Type=notify` (rclone signals readiness to systemd)
- `programs.fuse.userAllowOther = true` so Plex can read the FUSE mount
- Cache dir defaults to `~/.cache/rclone/vfs`; keep an eye on it against the 233G root

Plex transcode directory is `/tmp/plex-transcode` (created by `systemd.tmpfiles.rules`). `/tmp` is
tmpfs on this host, so partial transcodes hit RAM and never touch the SSD.

---

## Graphics & QuickSync

The N100 iGPU does the heavy lifting for Plex hardware transcoding (Gen12 graphics):

| Package              | Purpose                                      |
| -------------------- | -------------------------------------------- |
| `intel-media-driver` | VA-API driver for Gen12+ (media-hybrid path) |
| `vpl-gpu-rt`         | oneVPL runtime for QSV on 11th gen and newer |
| `intel-vaapi-driver` | Legacy VA-API fallback driver                |

Wired up in `hosts/plex/configuration.nix` via `hardware.graphics.extraPackages`. The `izaac` user
is in the `video` and `render` groups (`modules/core/user.nix`), which Plex needs because
`services.plex.user` is set to `izaac` instead of the default `plex` user (so it can read
`/srv/media`).

Verify hardware transcode works after a rebuild:

```bash
# VA-API report (expect iHD driver entry)
sudo -u izaac vainfo

# QSV session while a transcode runs
intel_gpu_top
```

---

## Network & Connectivity

| Device       | Model               | Interface | Driver | Notes                      |
| ------------ | ------------------- | --------- | ------ | -------------------------- |
| **Ethernet** | Realtek RTL8111 GbE | enp1s0    | r8169  | Primary link, always wired |
| **WiFi**     | Realtek RTL8822CE   | wlp2s0    | rtw88  | Present but unused         |

WiFi is intentionally unused: `networking.wireless.enable = false` means no supplicant ever
configures it, and `boot.blacklistedKernelModules = ["rtw88_8822ce"]` unbinds the Realtek card so no
`wlp2s0` link appears.

Tailscale runs for remote access (`mySystem.core.tailscale.enable`).

---

## Services

| Service           | State   | Purpose                                      |
| ----------------- | ------- | -------------------------------------------- |
| `plex`            | active  | Media server, runs as `izaac`, firewall open |
| `rclone-ul-crypt` | active  | Mounts `ul-crypt:` at `/srv/media` on boot   |
| `tailscaled`      | active  | Remote access                                |
| openssh           | enabled | LAN + tailnet admin access                   |

Deliberately off on this headless host (overridden in `hosts/plex/configuration.nix`): desktop,
gaming, virtualization/podman, printing, sops-nix, flatpak.

### Plex Media Server package

`services.plex.package` is pinned to `inputs.nix-packages.packages.<system>.plex` rather than
`pkgs.plex`. nixpkgs trails upstream by weeks (26.05 and unstable both shipped 1.43.2.10687 well
after 1.43.3.10896 landed with fixes for the CompanionProxy vulnerability, PM-5763, and network
modification of `TranscoderH264Options`, PM-5766). This box is reachable through the plex.tv relay,
so server-side security fixes should not wait on a channel bump.

The `plex` package in [izaac/nix-packages](https://github.com/izaac/nix-packages) overrides the
`version` and `src` of nixpkgs' `plexRaw` and feeds the result back into the stock FHS userenv, so
the NixOS module contract is untouched. A weekly workflow bumps it from the plex.tv downloads API.

Drop the override once nixpkgs catches up and stays current:

```bash
nix eval --raw .#nixosConfigurations.plex.config.services.plex.package  # what is deployed
nix eval --raw nixpkgs#plex.version                                     # what nixpkgs offers
```

---

## Power

Server duty: sleep is disabled at the source with `systemd.sleep.settings.Sleep` (`AllowSuspend=no`
and friends in `hosts/plex/configuration.nix`), so nothing can suspend the box, no matter what holds
or lacks an inhibitor lock. Background jobs such as `ul-migrate` still take `block` inhibitor locks;
harmless, they just never get tested by a suspend.

---

## Overnight Stability

Two hangs landed inside Plex's default butler window of 02:00-05:00, on 2026-08-31 at 03:31 and
2026-09-03 at 03:32. `GenerateBIFBehavior="scheduled"` means thumbnail generation demuxes the
library overnight, which is what put the box under load both times.

The first hang left an oops:

```text
BUG: kernel NULL pointer dereference, address: 0000000000000038
RIP: 0010:__alloc_tagging_slab_alloc_hook+0x7a/0x1c0
Comm: dmx0:matroska,w   Not tainted 6.18.47 #1-NixOS
```

`__alloc_tagging_slab_alloc_hook` is the memory allocation profiling instrumentation
(`CONFIG_MEM_ALLOC_PROFILING_ENABLED_BY_DEFAULT=y`), not Plex code: the profiler itself faulted
under the slab churn of the demux. The second hang logged nothing at all, which is the signature of
a hard lockup rather than an oops.

Two mitigations in `hosts/plex/configuration.nix`:

| Setting                   | Value | Why                                                      |
| ------------------------- | ----- | -------------------------------------------------------- |
| `sysctl.vm.mem_profiling` | `0`   | Boot param; removes the faulting code path. No use here. |
| `kernel.panic`            | `30`  | Reboot 30s after a panic instead of halting forever.     |
| `kernel.panic_on_oops`    | `1`   | Promote an oops to a panic so the reboot actually fires. |
| `kernel.hardlockup_panic` | `1`   | Let the NMI watchdog panic on a silent lockup.           |

The panic settings matter as much as the fix: the kernel default (`kernel.panic = 0`) is to hang
indefinitely, so both incidents cost hours of downtime waiting on a manual power cycle.

Verify after a rebuild:

```bash
cat /proc/sys/vm/mem_profiling                       # expect 0
sysctl kernel.panic kernel.panic_on_oops             # expect 30 and 1
journalctl --list-boots                              # unexpected gaps mean it happened again
journalctl -b -1 -k | grep -E 'BUG:|Oops:|Comm:'     # trace from the last crash, if any
```

---

## Troubleshooting

### Check the rclone mount

```bash
systemctl status rclone-ul-crypt
journalctl -u rclone-ul-crypt -n 50
mountpoint /srv/media && ls /srv/media
```

Systemd logs CPU/IO/network totals per run when the service restarts; memory peak around 6G with the
current buffer/cache settings is normal on this box.

### Check QuickSync during playback

```bash
sudo -u izaac vainfo                 # expect iHD + Gen12 profiles
intel_gpu_top                        # Video engine busy during transcode
```

### WiFi interface missing

Expected. See [Network & Connectivity](#network--connectivity): no supplicant and the `rtw88_8822ce`
driver is blacklisted, so no wireless link exists.

---

_Generated from system introspection on 2026-08-25_
