# snail Desktop Session (SDDM, Plasma, Flatpak)

> **Last Updated**: 2026-11-21 **Host**: snail (Slackware 15.0+ current, no systemd) **Session**:
> SDDM plus KWin Wayland **Links**: [Shared Drive](snail-rclone.md) |
> [YubiKey Break-Glass](yubikey/README.md) | [Index](README.md)

---

## Why This File Exists

Slackware starts the graphical session differently than NixOS, and a few things that "just work" on
`ninja` silently do not here. Each entry below cost real time to diagnose, so they are recorded with
the reason, not just the fix.

## Startup Chain

```text
sddm
  -> PAM auth (pam_env.so in system-auth, auth stage only)
  -> /usr/bin/startplasma-wayland
     -> Plasma sources ~/.config/plasma-workspace/env/*.sh
     -> kwin_wayland
```

Notice what is missing: no login shell. `/etc/profile` and `/etc/profile.d/*.sh` are not executed
for a session started this way, which is why anything that only ships a `profile.d` snippet never
reaches the desktop.

## Flatpak Apps Missing From the Menu

Symptom: `flatpak list` shows apps, the desktop files exist, but the launcher has no entries, and
Flatpak prints that `XDG_DATA_DIRS` does not include its export paths.

Cause: `/etc/profile.d/flatpak.sh` is the only thing that appends the export paths, and it needs a
login shell. It never runs under SDDM, so `XDG_DATA_DIRS` stays unset.

Fix, per user, sourced by Plasma before the launcher builds its cache:

```bash
mkdir -p ~/.config/plasma-workspace/env
cat > ~/.config/plasma-workspace/env/10-flatpak.sh <<'SH'
#!/bin/sh
# SDDM starts the Plasma session without a login shell, so
# /etc/profile.d/flatpak.sh never runs and Flatpak exports stay out of
# XDG_DATA_DIRS. Without this, installed Flatpak apps do not show up in the
# menu and desktop files are not found until a shell-sourced session.
flatpak_share="$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share"
XDG_DATA_DIRS="$flatpak_share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
XDG_DATA_DIRS="$(printf '%s' "$XDG_DATA_DIRS" | awk -v RS=: '!seen[$0]++' | paste -sd: -)"
export XDG_DATA_DIRS
SH
chmod 755 ~/.config/plasma-workspace/env/10-flatpak.sh
```

Verify without logging out:

```bash
sh -c '. ~/.config/plasma-workspace/env/10-flatpak.sh; echo "$XDG_DATA_DIRS"'
```

Then log out and back in once, and inside the new session:

```bash
echo "$XDG_DATA_DIRS" | tr ':' '\n'      # both flatpak paths present
flatpak list --app --columns=application
```

## Running a Flatpak From a Terminal or SSH

Two host-side gaps surfaced when launching `tv.plex.PlexDesktop` from a shell.

**1. `xdg-dbus-proxy` is not installed by default.** Flatpak needs it as soon as the session bus is
visible, and without it bwrap dies before the app starts:

```text
bwrap: execvp /usr/bin/xdg-dbus-proxy: No such file or directory
```

Install it from alienbob (`slackpkg install xdg-dbus-proxy`). The Slackers copy shows as `[mask]`,
alienbob's does not.

**2. The session bus is not on the path you would guess.** On this install it is a random socket
under `/tmp`, not `/run/user/1000/bus`:

```bash
ENVPID=$(pgrep -u "$USER" -f plasmashell | head -1)
DBUS=$(tr '\0' '\n' < "/proc/$ENVPID/environ" | sed -n 's/^DBUS_SESSION_BUS_ADDRESS=//p')
export DBUS_SESSION_BUS_ADDRESS="$DBUS"
export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0
flatpak run --socket=wayland tv.plex.PlexDesktop
```

`--socket=wayland` is required because the shipped manifest only declares `pulseaudio` and `x11`.
Make it permanent per app:

```bash
flatpak override --user --socket=wayland tv.plex.PlexDesktop
```

Inside the desktop session (Konsole) none of this is needed, the environment is already correct.

Harmless noise seen on a working launch: Fontconfig complaints about `49-sansserif.conf` and
`Cannot load libcuda.so.1`. Neither stops the app.

## Flatpak Apps Abort From the Launcher (QT_QPA_PLATFORM Leak)

Symptom: an app launches fine from a shell but, from the launcher, the taskbar shows its icon
briefly and it closes. The app's own log shows only:

```text
/app/bin/Plex: line 52:     5 Aborted                    "$BASE_DIR"/bin/plex-bin "$@"
```

with no Qt output at all, which means it died before the platform plugin initialised.

Cause: the Plasma session exports `QT_QPA_PLATFORM=wayland`, the launcher passes its environment
through, and the Flatpak sandbox has no Wayland socket because the app manifest only declares
`pulseaudio` and `x11`. Qt is told to use a platform it cannot reach, and aborts.

Diagnosis method, useful for any Flatpak app here: run it with the entire plasmashell environment
instead of your shell's environment, then unset the suspects.

```bash
PID=$(pgrep -u "$USER" -f plasmashell | head -1)
( while IFS= read -r -d '' kv; do export "$kv"; done < "/proc/$PID/environ"
  unset QT_QPA_PLATFORM
  flatpak run tv.plex.PlexDesktop )
```

Aborts with the variable set, runs with it unset, and the culprit is `QT_QPA_PLATFORM`.

Fix, granting the missing socket instead of fighting the variable:

```bash
flatpak override --user --socket=wayland tv.plex.PlexDesktop
```

Verify with `flatpak override --user --show tv.plex.PlexDesktop`, which should list
`sockets=wayland;`.

Any other Flatpak app that aborts instantly from the launcher but works from a shell should get the
same treatment before anything else is suspected.

## Why Not `/etc/environment`

It is parsed by `pam_env.so`, and on this system that module sits in the `auth` stage of
`system-auth`, not `session`. At `auth` time `HOME` is not reliably set, so a per-user path cannot
be written there. The system path (`/var/lib/flatpak/exports/share`) could live in
`/etc/environment` for non-Plasma sessions, but the useful half is the per-user one, so the session
script is the correct place.

## Card Access From the Desktop vs SSH

Separate problem, same shape: the environment or policy layer, not the hardware.

- SSH sessions need the polkit rule from [hosts.md](yubikey/hosts.md), otherwise `pcscd` denies
  `org.debian.pcsc-lite.access_pcsc` and gpg reports `No such device` even with the card inserted.
- `/etc/rc.d/rc.pcscd` must stay executable. `slackpkg upgrade` of `pcsc-lite` resets it, and the
  card silently stops working at next boot.

## Troubleshooting

| Symptom                                                            | Cause                                                                   | Fix                                                                     |
| :----------------------------------------------------------------- | :---------------------------------------------------------------------- | :---------------------------------------------------------------------- |
| Flatpak warning about `XDG_DATA_DIRS`, no menu entries             | SDDM session never sources `profile.d`                                  | Add `~/.config/plasma-workspace/env/10-flatpak.sh`, log out and in      |
| Warning gone but apps still missing                                | KService cache built before the variable was exported                   | Log out and in, or `kbuildsycoca6 --noincremental`                      |
| Only system Flatpaks appear                                        | Per-user export path missing                                            | Keep `$HOME/.local/share/flatpak/exports/share` first in the list       |
| `bwrap: execvp /usr/bin/xdg-dbus-proxy: No such file or directory` | Host lacks the Flatpak bus proxy                                        | `sudo slackpkg install xdg-dbus-proxy`                                  |
| App aborts instantly from SSH                                      | Session bus address wrong, so `DBUS_SESSION_BUS_ADDRESS` points nowhere | Read the real address from `plasmashell`'s environ, see the SSH section |
| Card works locally but not over SSH                                | polkit `allow_any=no` on Slackware                                      | See [hosts.md](yubikey/hosts.md)                                        |
| Card stopped working after an upgrade                              | `rc.pcscd` reset to non-executable                                      | `sudo chmod +x /etc/rc.d/rc.pcscd && sudo /etc/rc.d/rc.pcscd start`     |
