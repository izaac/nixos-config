# Shared Drive on snail (rclone ul-crypt)

> **Last Updated**: 2026-11-21 **Host**: snail (Slackware 15.0-current, no systemd) **Remote**:
> `ul-crypt:` (ulozto, encrypted)

snail gets the same shared-drive workflow as `ninja`, but not the same implementation. `ninja` runs
rclone under a systemd user unit (`home/rclone.nix`), Slackware has no systemd, so the mount here is
a background process tracked by a pidfile. The command surface is kept identical on purpose: `ulc`
with `ul-mount` and `ul-umount` wrappers.

---

## Documentation Links

- [Secret Management](secrets.md)
- [YubiKey Break-Glass](yubikey/README.md)
- [Documentation Index](../README.md)

---

## Why Not Reuse `home/ulc.sh`

`home/ulc.sh` is driven by `systemctl --user` and relies on a Nix wrapper to inject `REMOTE`,
`MOUNT`, `CACHE`, `UNIT` and `RC_ADDR`. Neither exists on snail.

`templates/slackware/ulc.sh` is the portable variant. Same transfer verbs, same VFS flags, same
refresh-after-upload behaviour, but:

| Concern        | ninja                               | snail                                                  |
| :------------- | :---------------------------------- | :----------------------------------------------------- |
| Mount driver   | systemd user unit `rclone-ul-crypt` | background `rclone mount` plus `~/.cache/ul/mount.pid` |
| Autostart      | on demand via `ul-mount`            | on demand via `ul-mount`, nothing at boot              |
| Mount point    | `/mnt/data/ul`                      | `~/mnt/ul` (no root needed)                            |
| VFS cache      | `/mnt/data/ul-cache`                | `~/.cache/rclone`, capped 10G, same as ninja's flags   |
| Unmount        | `systemctl --user stop`             | `fusermount3 -uz` then kill the pid                    |
| Refresh socket | `127.0.0.1:5573`                    | `127.0.0.1:5573`                                       |
| Config source  | `~/.config/rclone/rclone.conf`      | same path, or decrypted from sops on demand            |

## Install

```bash
sudo slackpkg install rclone                 # 1.76 from Slackware's community repo
mkdir -p ~/.local/bin
# copy templates/slackware/ulc.sh from the repo to ~/.local/bin/ulc, mode 755

printf '#!/bin/sh\nexec "$HOME/.local/bin/ulc" mount "$@"\n'  > ~/.local/bin/ul-mount
printf '#!/bin/sh\nexec "$HOME/.local/bin/ulc" umount "$@"\n' > ~/.local/bin/ul-umount
chmod 755 ~/.local/bin/ul-mount ~/.local/bin/ul-umount

# make the helpers reachable from login shells
for f in ~/.zshrc ~/.profile; do
  grep -q 'HOME/.local/bin' "$f" 2>/dev/null || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$f"
done
```

Do not symlink `ul-mount` to `ulc`. The script dispatches on its first argument, so a symlink would
just print usage.

## Key Handling: Two Modes

The crypt keys and the ulozto account live in `secrets/rclone.yaml` under the key `ul_conf`,
encrypted to the three age recipients and the YubiKey (OR group, same shape as
`secrets/common.yaml`, see [sops-break-glass](yubikey/sops-break-glass.md)).

Provision the encrypted copy, which is safe to keep on snail:

```bash
# from ninja or any host with a sops key
sops -d secrets/rclone.yaml | ssh snail 'umask 077; mkdir -p ~/.config/ul; cat > ~/.config/ul/rclone.yaml'
```

### Ephemeral (recommended on snail)

snail's root filesystem is **not encrypted** (`ext4` on `nvme0n1p2`, no LUKS). Any persistent copy
of the rclone config therefore hands the crypt keys to anyone who takes the disk or pulls the drive.

With no `~/.config/rclone/rclone.conf` present, `ulc mount` decrypts `~/.config/ul/rclone.yaml` with
`sops` (card inserted, PIN and touch) into `/dev/shm/ul-rclone.conf`, mode `0600`, and keeps it for
the lifetime of the mount. Every follow-up command (`ulc ls`, `ulc cp`, and so on) reuses that file,
so the cost is one PIN and one touch per mount, not per command. `ul-umount` shreds it.

Commands run without a mount decrypt into a throwaway `/dev/shm` file and shred it on exit, because
there is nothing to keep it for.

rclone reads its config once at startup, so the mount itself survives the file being removed at
unmount time.

`/dev/shm` is tmpfs, so this never reaches the disk. snail has only zram swap, no disk swap, so it
cannot be swapped out either.

Requirements: `sops` binary (static release to `/usr/local/bin/sops`) and the YubiKey with `dec`
touch policy. Over SSH, export `GPG_TTY=$(tty)` first so pinentry-tty can prompt.

### Persistent (convenient, weaker)

```bash
sops -d --extract '["ul_conf"]' secrets/rclone.yaml |
  ssh snail 'umask 077; mkdir -p ~/.config/rclone
             install -m 600 /dev/null ~/.config/rclone/rclone.conf
             cat > ~/.config/rclone/rclone.conf'
```

`install -m 600 /dev/null` first matters: a plain `cat >` onto an existing file keeps the old
permissions, so a file created earlier with a loose umask would stay loose.

`ulc` prefers this file when it exists. It is `0600`, but on an unencrypted disk it is still
readable by anyone with the machine. Use it when the card is not at hand, and delete it when you are
done:

```bash
rm ~/.config/rclone/rclone.conf      # falls back to ephemeral mode
```

`ulc key` reports which mode is active.

## Usage

```bash
ul-mount                      # start the mount, wait until it is usable
ulc status                    # mounted? cache size?
ulc ls                        # top-level directories
ulc cp ~/Photos holiday       # upload, keep the source
ulc up  ~/Photos holiday      # upload, verify, delete the source
ulc get holiday/2026 ~/Pics   # download
ulc find invoice              # search the remote by name
ulc du holiday                # directory size
ulc mkdir archive
ulc refresh holiday           # re-read a directory into the mount
ul-umount
```

`ulc up` asks before creating an unknown top-level folder, because the source is deleted afterwards
and a typo would be expensive.

`UL_BWLIMIT` works as on ninja: `UL_BWLIMIT=2.5M`, or a timetable such as `"08:00,2.5M 23:00,off"`.
`UL_TRANSFERS` defaults to 4.

## Troubleshooting

| Symptom                                                 | Cause                                                   | Fix                                                                   |
| :------------------------------------------------------ | :------------------------------------------------------ | :-------------------------------------------------------------------- |
| `no rclone config: neither ... exists` (exit 78)        | Neither mode provisioned                                | Run the provisioning command above, then `ulc key`                    |
| `could not decrypt ... (card inserted? PIN and touch?)` | Ephemeral mode without the card, or the touch timed out | Insert the card, `export GPG_TTY=$(tty)`, retry, touch when it blinks |
| `sops not installed` (exit 69)                          | Ephemeral mode but no sops binary                       | Install the static release to `/usr/local/bin/sops`                   |
| `timed out waiting for ~/mnt/ul`                        | rclone exited at startup                                | `tail -15 ~/.cache/ul/mount.log`, usually credentials or network      |
| `Transport endpoint is not connected`                   | Mount died under a running shell                        | `ulc umount`, then `ul-mount`                                         |
| Nothing mounted after reboot                            | Slackware has no systemd unit here, by design           | `ul-mount` when wanted                                                |

## Rotating the Crypt Keys

The crypt password protects the remote contents, so a leak means re-encrypting everything on the
remote. Treat the values in `secrets/rclone.yaml` as high value, rotate only with a full
`rclone crypt` re-upload plan, and re-provision snail after any change.
