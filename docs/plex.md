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

Media lives on a crypt remote mounted at `/srv/media` by the `rclone-ul-crypt.service` unit defined
in `hosts/plex/configuration.nix`.

`ul-crypt:` is the alias used for the offsite media provider throughout this repo. It is a `crypt`
remote wrapping the provider's own remote, so filenames and contents are encrypted client-side and
the provider sees neither. The provider is deliberately not named here or in the config. To see what
it wraps:

```bash
rclone config show ul-crypt   # prints the wrapped remote name and its password fields
```

- Runs as `izaac`, `Type=notify` (rclone signals readiness to systemd)
- `programs.fuse.userAllowOther = true` so Plex can read the FUSE mount
- Cache dir defaults to `~/.cache/rclone/vfs`; keep an eye on it against the 233G root

The library is flat and large: roughly 6300 entries under `movies` alone. The provider paginates
directory listings at 500 entries, so one full listing costs about 13 sequential API round trips.
With rclone's default `--dir-cache-time` of 5 minutes that repeated every 5 minutes, and constantly
during a library scan, which is where most of the host's I/O pressure came from.

**Splitting the library into subfolders does not help.** Plex scans recursively, so the same 6300
entries are still fetched; the work is only spread across more directories. A flat library root is
also what Plex's own naming guide expects. The fix is cache tuning, not reorganisation:

| Flag                            | Value          | Why                                                   |
| ------------------------------- | -------------- | ----------------------------------------------------- |
| `--dir-cache-time`              | `72h`          | Default 5m meant re-listing 6300 entries continuously |
| `--attr-timeout`                | `1h`           | Default 1s; Plex stats every file it scans            |
| `--vfs-cache-mode`              | `full`         | Needed for seeking during playback                    |
| `--vfs-cache-max-size` / `-age` | `50G` / `168h` | Bounded against the 233G root                         |
| `--buffer-size`                 | `64M`          | In-memory read-ahead per open file                    |
| `--vfs-read-chunk-size` / limit | `32M` / `2G`   | Ramp up rather than many small ranged reads           |
| `--rc` on `127.0.0.1:5572`      |                | Lets the dir cache be refreshed on demand, see below  |

#### Refreshing after an upload

The backend reports `ChangeNotify: false`, so `--poll-interval` cannot detect changes and the 72h
cache would otherwise hide new files for up to three days.

Writing **through the mount** invalidates the cache immediately. Uploading **straight to the
remote** does not, so refresh it afterwards:

```bash
rclone move "Some Movie 2026 1080p.mkv" ul-crypt:movies/ --progress --check-first
rclone rc --rc-addr 127.0.0.1:5572 --rc-no-auth vfs/refresh dir=movies
```

Prefer `rclone move` over `mv` into the mount: it verifies the upload before deleting the source and
keeps the transfer out of the VFS cache. The control socket is loopback-only and the firewall does
not open the port.

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

Five hangs so far, every one inside Plex's 02:00-05:00 butler window:

| When             | Downtime | Oops? | Recovered by       |
| ---------------- | -------- | ----- | ------------------ |
| 2026-08-31 03:31 | 6h 35m   | yes   | manual power cycle |
| 2026-09-03 03:32 | 3h 24m   | no    | manual power cycle |
| 2026-09-05 04:14 | 54s      | no    | `kernel.panic`     |
| 2026-09-06 02:53 | 2m 34s   | no    | hardware watchdog  |
| 2026-09-06 03:46 | 1m 45s   | no    | hardware watchdog  |

The first left an oops:

```text
BUG: kernel NULL pointer dereference, address: 0000000000000038
RIP: 0010:__alloc_tagging_slab_alloc_hook+0x7a/0x1c0
Comm: dmx0:matroska,w   Not tainted 6.18.47 #1-NixOS
```

`__alloc_tagging_slab_alloc_hook` is the memory allocation profiling instrumentation
(`CONFIG_MEM_ALLOC_PROFILING_ENABLED_BY_DEFAULT=y`), not Plex code: the profiler itself faulted
under the slab churn of the demux.

The other four logged nothing at all. The 09-05 one looked like it hit while idle, but that reading
came from the journal, which only captures Plex's stdout; Plex's real work never appears there. The
transcoder statistics logs tell a different story, and the butler window turned out to be the
correlation that matters, not a coincidence.

### The butler window

`Preferences.xml` carries no `ButlerStartHour` or `ButlerEndHour`, so Plex fell back to its built-in
maintenance window of **02:00-05:00**. Every hang landed inside it, five for five. With
`GenerateBIFBehavior="scheduled"` the overnight work includes thumbnail generation, which seeks
through every video, plus loudness analysis, which decodes audio out to FLAC. All of it reads
through the rclone media mount. Caught in the act before the 02:53 hang:

```text
02:27:49  02:28:04  02:28:16  02:28:32  02:28:46  02:29:00
videoDecision="ignore" audioDecision="transcode" transcodeHwRequested="1"
```

### Why that killed an 8G box

Every escape valve on this host was also RAM:

| Resource          | Backing                | Note                                      |
| ----------------- | ---------------------- | ----------------------------------------- |
| Transcode scratch | `/tmp`, a tmpfs        | `PrivateTmp=true`, so systemd's own tmpfs |
| Swap              | zram at 100% of RAM    | compressed pages, still resident          |
| rclone buffers    | `--buffer-size 64M`    | per open file                             |
| rclone VFS cache  | disk, pegged at 49/50G | constant writeback and eviction           |

tmpfs pages can only be evicted to swap, and swap was zram, which is RAM. Batch-transcoding FLAC
into a 3.8G tmpfs on a 7.5G box, while rclone streamed downloads and flushed its cache to one SATA
SSD, drove the kernel into a reclaim stall.

That explains the evidence the C-state theory could not. Notably the **NMI watchdog never fired**:
it detects a CPU spinning with interrupts off, and tasks blocked in D-state on I/O are not that, so
it correctly stayed silent. Only the hardware watchdog recovered the box, because systemd's own ping
thread was blocked too. journald could not write, which is why nothing was ever logged.

Ruled out along the way: the r8169 NIC (ASPM already disabled, no runtime errors), the constant IPv6
prefix churn from tailscale and dhcpcd (~14 link changes an hour, all day, uncorrelated), thermals
(50 C against a 105 C limit), ECC (zero errors), and SATA (zero ATA exceptions across every boot).

### On the C-state theory, and the BIOS

An earlier revision of this page blamed a deep package C-state wedge. That is not dead, but it is no
longer the leading explanation, and it never accounted for the butler correlation. Worth recording
what the research turned up:

- There is **no Alder Lake-N C-state erratum**. `intel_idle` exposes C10 for Gracemont with no quirk
  or `UNUSABLE` flag, in contrast to Bay Trail, which gets an explicit workaround in the same file.
- There is a close same-CPU precedent on a **different board** (ASRock N100M, TrueNAS): unresponsive
  overnight, clean logs, fixed with `intel_idle.max_cstate=1`. Same CPU only, not the same machine.
- **PELADN publishes no BIOS for the WI-6 at all.** Their downloads page lists only driver packs and
  a Windows image; a Wayback sweep of the whole domain returns zero URLs containing "bios", and
  their support page states they do not supply BIOS files and void the warranty if one is flashed.
- A BIOS update would not be applicable anyway: the SMBIOS firmware inventory reports
  `Firmware ID: 00000000-0000-0000-0000-000000000000`, matching the all-zero GUID in the ESRT entry,
  so there is no capsule identity for fwupd or anything else to target. PELADN is absent from LVFS.
- Microcode is already current and is **not** the stale part: the BIOS ships revision `0x0f` from
  2024, and Linux early-loads `0x21` from `microcode-intel-20260812` on every boot.

So the firmware route is closed. C-states are still deliberately left uncapped, because capping them
now would mask whichever cause is real.

### Mitigations

Recovery, in `hosts/plex/configuration.nix`:

| Setting                                       | Value | Covers                                                   |
| --------------------------------------------- | ----- | -------------------------------------------------------- |
| `sysctl.vm.mem_profiling`                     | `0`   | Boot param; removes the faulting code path. No use here. |
| `kernel.panic`                                | `30`  | Reboot 30s after a panic instead of halting forever.     |
| `kernel.panic_on_oops`                        | `1`   | Promote an oops to a panic so the reboot actually fires. |
| `kernel.hardlockup_panic`                     | `1`   | Let the NMI watchdog panic on a silent lockup.           |
| `systemd.settings.Manager.RuntimeWatchdogSec` | `60s` | Hardware watchdog for a CPU too wedged to panic.         |

These are not redundant: the sysctls need a kernel alive enough to run its own panic path, while the
hardware watchdog is silicon and resets the board even when nothing can execute. Only the watchdog
has actually fired so far, which is itself evidence for the stall diagnosis. It cut the 09-06 hangs
to 2m34s and 1m45s, against 6h35m and 3h24m before it existed.

Cause, same file:

| Setting                           | Value                      | Why                                             |
| --------------------------------- | -------------------------- | ----------------------------------------------- |
| `TranscoderTempDirectory`         | `/var/lib/plex/Transcode`  | Scratch on disk instead of the PrivateTmp tmpfs |
| `zramSwap.memoryPercent`          | `50` (desktop default 100) | Stop trading real RAM for compressed RAM        |
| `swapDevices`                     | 8G file on `/`             | A real place to evict to                        |
| `vm.swappiness`                   | `60` (desktop default 180) | Do not thrash into RAM-backed swap              |
| `vm.dirty_ratio` / `_background_` | `5` / `2` (desktop 10 / 5) | Percentages of RAM: 10% of 8G is a long flush   |

The desktop values live in `modules/core/performance.nix` and are tuned for ninja's 64G. They are
`mkDefault` so a small-memory host can override them; plex does.

### Taming the analysis workload

The other half of the fix is doing less work at all. Every analysis task reads file **content**
through the network mount, which is far more expensive here than on a local disk. Plex Pass enables
most of them by default, including several that produce nothing on this server.

| Setting                          | Value       | Reason                                                                                                                                                                                  |
| -------------------------------- | ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `GenerateBIFBehavior`            | `never`     | Preview thumbnails read every file end to end. Plex's own default is `never`, and its docs warn against enabling it on a large existing library                                         |
| `LoudnessAnalysisBehavior`       | `never`     | No music library                                                                                                                                                                        |
| `MusicAnalysisBehavior`          | `never`     | No music library                                                                                                                                                                        |
| `GenerateAdMarkerBehavior`       | `never`     | DVR only, no tuner on this host                                                                                                                                                         |
| `GenerateChapterThumbBehavior`   | `scheduled` | Kept, deferred to the butler window                                                                                                                                                     |
| `GenerateIntroMarkerBehavior`    | `scheduled` | Was `asap`; Skip Intro still works                                                                                                                                                      |
| `GenerateCreditsMarkerBehavior`  | `scheduled` | Was `asap`; Skip Credits still works                                                                                                                                                    |
| `ScheduledLibraryUpdateInterval` | `21600`     | 6h, was hourly. Plex cannot get change notifications from a network mount, so scanning is how new media is found, but hourly re-queued analysis far more often than the library changes |

`asap` means "when media is added **and** as a scheduled task", so moving the marker tasks to
`scheduled` only stops them firing on import. Nothing already generated is removed by any of this;
these settings govern future work only.

The butler window itself stays at Plex's usual **02:00-05:00**, since the box is idle then and the
workload above is now much smaller.

### Declarative Plex settings

Plex rewrites `Preferences.xml` itself (tokens, machine identifier, anything changed in the UI), so
it cannot be a store symlink. Instead `systemd.services.plex-preferences` stamps only the keys that
must not drift, before each start, using `xmlstarlet` to insert-or-update. It is idempotent and
leaves the other keys alone.

Changing one of these in the Plex UI works until the next `plex.service` restart, at which point the
value in `hosts/plex/configuration.nix` wins. To change one for real, edit it there and rebuild.
Note that `nh os switch` does not restart `plex.service` on its own, so the stamp does not take
effect until Plex is restarted:

```bash
sudo systemctl restart plex
```

Verify after a rebuild:

```bash
cat /proc/sys/vm/mem_profiling                       # expect 0
sysctl kernel.panic kernel.panic_on_oops             # expect 30 and 1
sysctl vm.swappiness vm.dirty_ratio                  # expect 60 and 5
systemctl show -p RuntimeWatchdogUSec --value        # expect 60000000
cat /sys/class/watchdog/watchdog0/state              # expect active
swapon --show                                        # expect zram AND /var/swapfile
findmnt -no FSTYPE /var/lib/plex/Transcode           # expect ext4, NOT tmpfs
journalctl --list-boots                              # unexpected gaps mean it happened again
journalctl -b -1 -k | grep -E 'BUG:|Oops:|Comm:'     # trace from the last crash, if any

# Butler window and transcode path actually in force
grep -oE '(Butler|Generate|Loudness|Music|Transcoder|Scheduled)[A-Za-z]*="[^"]*"' \
  '/var/lib/plex/Plex Media Server/Preferences.xml'
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
