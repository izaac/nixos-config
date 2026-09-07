# Hardware Configuration - plex

> **Last Updated**: 2026-09-06 **System**: PELADN Intel N100 Mini PC **OS**: NixOS 26.05

---

## System Overview

| Component   | Model                             | Notes                                        |
| ----------- | --------------------------------- | -------------------------------------------- |
| **Mini PC** | PELADN (Intel N100)               | Headless server, wired ethernet only         |
| **CPU**     | Intel N100 (Alder Lake-N)         | 4-Core, 4-Thread, up to 3.4 GHz, low TDP     |
| **GPU**     | Intel UHD Graphics (Alder Lake-N) | `8086:46d1`, QuickSync transcoding for Plex  |
| **RAM**     | 16GB DDR4-3200 SODIMM             | Single stick, A-DATA 1Rx8, non-ECC           |
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

Tailscale runs here, and this host carries the tailnet's routing duties (`mySystem.core.tailscale`):
it advertises the LAN subnet and offers itself as an exit node. Both moved here from ninja because
this box is always on, where a workstation is not. Both also need one-time approval in the Tailscale
admin console before other devices can use them.

Because it forwards traffic, the module gives this host `useRoutingFeatures = "server"` (IP
forwarding), loose reverse-path filtering, and UDP GRO offload on `enp1s0`. It is also the one host
with `acceptDns = true`, so MagicDNS resolves tailnet names here; the workstations keep LAN DNS.

---

## Services

| Service             | State   | Purpose                                      |
| ------------------- | ------- | -------------------------------------------- |
| `plex`              | active  | Media server, runs as `izaac`, firewall open |
| `rclone-ul-crypt`   | active  | Mounts `ul-crypt:` at `/srv/media` on boot   |
| `tailscaled`        | active  | Remote access, subnet router, exit node      |
| `tailscale-udp-gro` | active  | UDP GRO offload on `enp1s0` for forwarding   |
| openssh             | enabled | LAN + tailnet admin access                   |

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

Seven hangs so far. The first five all landed inside Plex's 02:00-05:00 butler window; the last two
did not, which is what eventually ruled the window out as the cause on its own.

| When             | Downtime | Oops? | Recovered by       | Load at the time     |
| ---------------- | -------- | ----- | ------------------ | -------------------- |
| 2026-08-31 03:31 | 6h 35m   | yes   | manual power cycle | butler               |
| 2026-09-03 03:32 | 3h 24m   | no    | manual power cycle | butler               |
| 2026-09-05 04:14 | 54s      | no    | `kernel.panic`     | butler               |
| 2026-09-06 02:53 | 2m 34s   | no    | hardware watchdog  | butler, 6 transcodes |
| 2026-09-06 03:46 | 1m 45s   | no    | hardware watchdog  | butler               |
| 2026-09-06 13:39 | 8m       | no    | manual power cycle | deep media analysis  |
| 2026-09-06 19:11 | ~60s     | no    | hardware watchdog  | ffmpeg + rclone      |

The first left an oops:

```text
BUG: kernel NULL pointer dereference, address: 0000000000000038
RIP: 0010:__alloc_tagging_slab_alloc_hook+0x7a/0x1c0
Comm: dmx0:matroska,w   Not tainted 6.18.47 #1-NixOS
```

`__alloc_tagging_slab_alloc_hook` is the memory allocation profiling instrumentation
(`CONFIG_MEM_ALLOC_PROFILING_ENABLED_BY_DEFAULT=y`), not Plex code: the profiler itself faulted
under the slab churn of the demux.

The rest logged nothing **to the journal**, which for a long time was mistaken for logging nothing
at all. They are all recorded: journald cannot flush to disk while the kernel is dying, but the
kernel writes its ring buffer into EFI variables through `efi_pstore`, and `systemd-pstore` moves
those into `/var/lib/systemd/pstore/<epoch>/` on the next boot. There is a dump there for every
hang.

```bash
sudo ls /var/lib/systemd/pstore/                     # one directory per crash
sudo tail -70 /var/lib/systemd/pstore/<epoch>/001/dmesg.txt   # the fault is at the end
```

The dump is written in numbered parts, newest last, so the oops itself is at the _tail_ of
`dmesg.txt` while the head is early boot.

### What the dumps actually say

| When        | Faulting task     | Signature                                                     |
| ----------- | ----------------- | ------------------------------------------------------------- |
| 08-31 03:31 | `dmx0:matroska,w` | NULL deref in `__alloc_tagging_slab_alloc_hook`               |
| 09-06 02:53 | `swapper/*`       | NULL deref in `update_sd_lb_stats` (scheduler load balancer)  |
| 09-06 03:46 | `av:hevc:df1`     | `exc_control_protection`, RIP `check_preempt_wakeup_fair+0x0` |
| 09-06 19:11 | `af#0:7`          | instruction fetch at `0x355746a0`, a truncated kernel pointer |

Different code every time, always in the hottest paths (scheduler tick, load balancer, idle enter),
always "Not tainted", across two kernel versions. That is not one kernel bug.

The 09-06 19:11 dump is the clearest. The kernel branched to `0x00000000355746a0`; the value it
should have held is `0xffffffffb55746a0`, still visible in a nearby register. The low three bytes
are intact and the top 33 bits are gone, so a live function pointer was corrupted in flight. The
09-06 03:46 dump is the same class from the other direction: `exc_control_protection` is the CET
handler, raised when an indirect branch lands somewhere it was never allowed to.

Random control-flow corruption in whatever happens to be executing is the signature of unstable
hardware, not of a driver. The 09-06 03:46 dump proves it outright, because the oops prints the
machine code around the faulting instruction:

```text
RIP: 0010:check_preempt_wakeup_fair+0x0/0x450
Code: ... 0f 1f 80 00 00 00 00 97 90 90 90 90 90 90 90 13 90 90 90 90 90 90 90 <71> 0f 1e fa ...
```

Everything between the alignment `nop` and the function entry is compiler padding and must read
`90`, and the entry itself must be `endbr64`, `f3 0f 1e fa`. In memory those bytes read `97`, `13`
and `71`. **Kernel executable text was corrupted in RAM.** That is also the mechanism of the crash:
with `f3` broken to `71` the `endbr64` no longer exists, so Intel IBT raised a control-protection
fault on the indirect call into that function, and `exc_control_protection` ended at its `UD2`
("invalid opcode"). CET is a hardware integrity check on kernel code, and it caught the corruption.

Software cannot do this. Kernel text is mapped read-only, and the wrong bytes are wrong in several
independent places.

The board carries a single non-ECC DDR4-3200 SODIMM (`Error Correction Type: None`), so nothing
detects or corrects a flip. `igen6_edac` loads but reports nothing, because there is no ECC for it
to report; the earlier note on this page reading that silence as "ECC: zero errors" was wrong.

**The fix is the RAM.**

Replaced on 2026-09-06 21:05. The original no-name `DDR4 NB 8G 3200` module (JEDEC bank 13, ID
`0x0CC7`) came out, and a spare A-DATA 16G `AO1P32NCSV1-BDBS`, 1Rx8 DDR4-3200, went in. Confirmed
running at full 3200 MT/s.

`stressapptest` was run against the old module first and passed 13 minutes clean, which is worth
recording as a negative result: the corruption surfaces roughly once every few hours, so a short
stress pass proves nothing either way. The pstore dumps are the evidence, not the stress test.

A second identical A-DATA module is on the shelf. If hangs continue on this one, swap to it before
suspecting anything else, since that isolates the DIMM from the slot and the memory controller.

**Watch for:** a new dump appearing under `/var/lib/systemd/pstore/`. If none shows up over a week
of normal use including the butler window, the RAM was the fault.

### The butler window

`Preferences.xml` carries no `ButlerStartHour` or `ButlerEndHour`, so Plex fell back to its built-in
maintenance window of **02:00-05:00**. The first five hangs all landed inside it, which looked
conclusive at the time; the 13:39 and 19:11 hangs later broke the pattern. What the window really
explains is _why the box was busy_, not why it fell over. With `GenerateBIFBehavior="scheduled"` the
overnight work includes thumbnail generation, which seeks through every video, plus loudness
analysis, which decodes audio out to FLAC. All of it reads through the rclone media mount. Caught in
the act before the 02:53 hang:

```text
02:27:49  02:28:04  02:28:16  02:28:32  02:28:46  02:29:00
videoDecision="ignore" audioDecision="transcode" transcodeHwRequested="1"
```

### Why that killed an 8G box

Historical: the box ran on 8G until 2026-09-06 and is now on 16G. This was the original working
theory, and the fixes below are worth keeping on their own merits, but the pstore dumps do not
support it as the cause: a reclaim stall does not corrupt function pointers. Read it as "the box was
badly configured for 8G and is no longer", not as the explanation for the hangs.

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
thread was blocked too. journald could not write, which is why nothing reached the journal, though
the kernel still made it into pstore.

Ruled out along the way: the r8169 NIC (ASPM already disabled, no runtime errors), the constant IPv6
prefix churn from tailscale and dhcpcd (~14 link changes an hour, all day, uncorrelated), thermals
(50 C against a 105 C limit), and SATA (zero ATA exceptions across every boot). ECC was recorded as
"zero errors", which was misread: this board has no ECC to report any.

### On the C-state theory, and the BIOS

Worth recording what the research turned up:

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

So the firmware route is closed. C10 is capped (`max_cstate=4`) and stays capped, but the theory is
retired: the pstore dumps show corrupted kernel text, which no idle transition explains.

`max_cstate=1` was tried and reverted. On this CPU it leaves **no usable idle state at all** rather
than just C1:

```text
intel_idle: max_cstate 1 reached
$ ls /sys/devices/system/cpu/cpu0/cpuidle/     # state0 only, and state0 is POLL
```

The cores then busy-loop, and the idle package temperature went from 50 C to 70 C. Since DRAM
retention time falls as temperature rises, that setting works against the real fault. Do not lower
the cap below 4 on this box.

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
has actually fired so far. It cut the 09-06 hangs to 2m34s and 1m45s, against 6h35m and 3h24m before
it existed.

Tuning, same file. All of it dates from the 8G era; the right-hand column is why each one is still
there on 16G:

| Setting                           | Value                      | Still there because                              |
| --------------------------------- | -------------------------- | ------------------------------------------------ |
| `TranscoderTempDirectory`         | `/var/lib/plex/Transcode`  | Scratch on disk instead of the PrivateTmp tmpfs  |
| `vm.dirty_ratio` / `_background_` | `5` / `2` (desktop 10 / 5) | The single SATA SSD. 10% of 16G is 1.6G to flush |
| `vm.swappiness`                   | `60` (desktop default 180) | 180 assumes swap is zram; this host swaps to SSD |
| `zramSwap.memoryPercent`          | `50` (desktop default 100) | Conservative for a server. Optional now          |
| `swapDevices`                     | 8G file on `/`             | Cheap insurance. Optional now                    |

Note the dirty ratios are percentages **of RAM**, so more memory means a larger writeback burst, not
a smaller one. That setting became more relevant after the upgrade, not less. Measured on 16G with a
`dialogue-boost` run in progress: 1.3G used, 14.4G available, memory pressure flat at 0.00.

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
| `GenerateIntroMarkerBehavior`    | `never`     | Was `scheduled`. Decodes the whole file, see below                                                                                                                                      |
| `GenerateCreditsMarkerBehavior`  | `never`     | Was `scheduled`. Decodes the whole file, see below                                                                                                                                      |
| `ScheduledLibraryUpdateInterval` | `21600`     | 6h, was hourly. Plex cannot get change notifications from a network mount, so scanning is how new media is found, but hourly re-queued analysis far more often than the library changes |

`asap` means "when media is added **and** as a scheduled task", so moving a task to `scheduled` only
stops it firing on import. Nothing already generated is removed by any of this; these settings
govern future work only, so markers detected before the change are still there.

#### Why the marker tasks went from scheduled to never

`scheduled` is not a guarantee. Asking Plex to re-read one item, with
`PUT /library/metadata/<id>/analyze`, runs the marker passes **immediately**, whatever the behaviour
setting says. That surfaced while `dialogue-boost.sh` was adding audio tracks: each rewritten file
was handed to Plex to re-read, and each one spawned

```text
Plex Media Scanner -C -f /srv/media/movies/<film>.mkv --log-file-suffix Credits \
  --creditsTempDataPath /tmp/PlexCreditsDetection-...
```

at over 100% CPU, pulling the file over the network a second time immediately after it had been
downloaded, encoded and uploaded. Load sat above 5 with two rclone transfers competing.

Intro and credits detection both decode the entire film. On a local disk that is merely slow; on a
4.6 TB cloud mount it doubles the transfer for every file touched. Chapter thumbnails stay on
because they sample frames rather than decoding everything.

Note `--creditsTempDataPath` points into `/tmp`, which is a tmpfs under `PrivateTmp=true`, so that
scratch data is RAM.

Separately, three Scheduled Tasks are disabled outright. `ButlerTaskDeepMediaAnalysis` is the task
that was running during the 2026-09-06 13:39 hang; it and `ButlerTaskUpgradeMediaAnalysis` each walk
the whole library reading file content over the network, and `ButlerTaskRefreshEpgGuides` does
nothing without a DVR tuner. The cheap local tasks stay on: database backup and optimise, bundle and
cache cleanup, blob garbage collection, and metadata refresh.

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
