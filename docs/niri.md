# Niri Compositor

> **Hosts**: Linux (`ninja`, `windy`)
> **Defined in**: [`home/niri.nix`](../home/niri.nix), `programs.niri.settings`

[Niri](https://github.com/YaLTeR/niri) is the scrollable-tiling Wayland
compositor on both Linux hosts, wired in through
[niri-flake](https://github.com/sodiboo/niri-flake). It owns the outermost layer
of the desktop: monitors, workspaces, windows and global hotkeys. The terminal
stack ([Kitty](kitty.md) with [tmux](tmux.md) inside it) lives one level down,
launched by niri and never competing for the same keys. See
[How niri, Kitty and tmux interact](#how-niri-kitty-and-tmux-interact).

`Mod` is the **Super** (logo) key. Most window and workspace binds use it, so it
never overlaps with the terminal layers below, which lead with `Ctrl+Shift` or
the `Ctrl+a` tmux prefix.

## Desktop shells

`home/niri.nix` only holds bindings that are the same whichever desktop shell is
running. Anything that talks to the shell (launcher, lock, session menu,
clipboard, media and brightness keys) is defined by the shell module itself, so
the two hosts can differ:

| Host    | Shell module                                                                  | Shell                                                   |
| ------- | ----------------------------------------------------------------------------- | ------------------------------------------------------- |
| `ninja` | [`home/ashell.nix`](../home/ashell.nix) + [`home/lock.nix`](../home/lock.nix) | [ashell](https://github.com/MalpenZibo/ashell)          |
| `windy` | [`home/noctalia.nix`](../home/noctalia.nix)                                   | [Noctalia](https://github.com/noctalia-dev/noctalia) v5 |

The tables below document the `ninja` (ashell) bindings. `windy` keeps the
previous Noctalia bindings unchanged; see `home/noctalia.nix`.

---

## Keybindings

### Apps & session

| Keys          | Action                                  |
| ------------- | --------------------------------------- |
| `Mod+Return`  | Launch Kitty (terminal)                 |
| `Mod+D`       | App launcher (fuzzel)                   |
| `Alt+Space`   | App launcher (Moonlight-friendly alias) |
| `Mod+E`       | File manager (nemo)                     |
| `Mod+B`       | Browser (firefox)                       |
| `Mod+V`       | Clipboard history (stash + fuzzel)      |
| `Mod+Shift+W` | Wallpaper picker (fuzzel)               |
| `Mod+Ctrl+L`  | Lock screen (swaylock)                  |
| `Mod+Shift+P` | Session menu (wlogout)                  |
| `Mod+Shift+S` | Audio sink picker (fuzzel)              |
| `Mod+Q`       | Close window                            |
| `Mod+Shift+E` | Quit niri (no confirmation)             |

ashell exposes no "toggle panel" IPC, so the control center and the notification
centre have no keybind: click the **Settings** and **Notifications** modules in
the bar instead. This replaces the old `Mod+S` and `Mod+Shift+N`.

### Direct power actions

| Keys               | Action    |
| ------------------ | --------- |
| `Mod+Ctrl+Shift+S` | Suspend   |
| `Mod+Ctrl+Shift+R` | Reboot    |
| `Mod+Ctrl+Shift+Q` | Power off |

### Idle & lock

`swayidle` locks the screen with `swaylock` after 8 minutes idle, then powers the
displays off via `niri msg action power-off-monitors` after 12 minutes; any input
turns them back on. Suspend is never automatic and stays a manual action
(`Mod+Ctrl+Shift+S`, the session menu, or the ashell settings panel). The screen
also locks before sleep and on `loginctl lock-session`. Unlock with a YubiKey
touch or your password. Manual lock is `Mod+Ctrl+L`.

swaylock's `--grace` option is deliberately not set. It unlocks on any mouse or
key event for N seconds without a password, which would let the machine be woken
straight back up moments after the idle timer locked it.

`swaylock` and `swayidle` are the only two C programs left in this stack. Every
Rust Wayland locker surveyed is unproven (the largest has 83 stars, the next is
dead since 2025) and `waylock` is Zig, not Rust, so the lock screen stays on the
battle-tested implementation.

### The session wrapper

niri's `spawn-at-startup` launches `ashell-session`, which owns the whole shell
lifecycle for the session. It starts `awww-daemon`, restores the last wallpaper,
then supervises `ashell` itself: a crash is restarted after two seconds, five
instant failures in a row give up with a notification, and a vanished Wayland
socket ends the loop rather than respawning into a dead session.

A `flock` guard means only one wrapper runs per session. That matters because
this host lingers the user manager and sets `KillUserProcesses=false`, so a
previous session's processes can outlive logout; without the lock a re-login
could end up with two bars fighting over the notification and tray D-Bus names.

To restart the shell by hand, kill `ashell` and the wrapper brings it back.

### Wallpaper & theming

The [awww](https://codeberg.org/LGFae/awww) daemon draws the wallpaper, started
by the `ashell-session` wrapper at login. Wallpapers are read from
`~/Pictures/Wallpapers`, an out-of-store symlink to the `~/repos/wallpapers` git
checkout, so adding images needs no rebuild.

The `set-wallpaper` helper is the entry point:

| Command                   | Effect                                |
| ------------------------- | ------------------------------------- |
| `set-wallpaper pick`      | category, then image, with thumbnails |
| `set-wallpaper random`    | pick one at random (the default)      |
| `set-wallpaper /path.png` | set a specific file                   |

`pick` asks for a category first; Escape or the Back row returns to it. fuzzel
has no libjpeg, so previews come from a 256px PNG cache in
`~/.cache/wallpaper-thumbs`, refreshed only when the source is newer.

It applies the image, records the choice in `~/.local/state/current-wallpaper` so
it survives a logout, and then runs [matugen](https://github.com/InioX/matugen)
to regenerate the shell palette.

ashell keeps its colors inside `config.toml` and has no separate theme file, so
that file is **not** managed declaratively. Instead Nix generates a matugen
template at `~/.config/matugen/templates/ashell.toml` holding the full ashell
configuration with only the `[appearance]` colors left as placeholders; matugen
renders it to `~/.config/ashell/config.toml`, and ashell hot-reloads. Layout is
therefore declarative and reviewable in git while colors follow the wallpaper.
Home Manager re-renders that file on every activation, so a rebuild that changes
the template applies immediately instead of waiting for the next wallpaper.

Semantic colors (`success`, `warning`, `danger`) are pinned to the static
Catppuccin palette rather than derived from the wallpaper, because a
wallpaper-derived "danger" could come out green. Stylix still owns application
colors (see [kitty](kitty.md), [tmux](tmux.md)), so terminals and GTK apps stay
on the static Catppuccin Mocha palette.

### Network indicators

ashell's network and VPN support talks only to NetworkManager. `ninja` runs
systemd-networkd with `networking.networkmanager.enable` forced off, so those
indicators are omitted there; `windy` runs NetworkManager and keeps the full
network and VPN panels.

The service behind them cannot be disabled from the config, and upstream retries
a failed backend connection every five seconds for the whole session with no
backoff and no give-up. On a host with neither NetworkManager nor iwd that is a
permanent loop: roughly 17k D-Bus round trips and 3 MB of log a day. The overlay
in `overlays/ashell-unstable.nix` carries a patch adding exponential backoff and
a six-attempt limit, after which the service parks. Re-check that patch against
`src/services/network/mod.rs` on every ashell bump.

### Focus & move

| Keys                      | Action                    |
| ------------------------- | ------------------------- |
| `Mod+←/→` or `Mod+H/L`    | Focus column left / right |
| `Mod+↑/↓` or `Mod+K/J`    | Focus window up / down    |
| `Mod+Shift+←/→` or `+H/L` | Move column left / right  |
| `Mod+Shift+↑/↓` or `+K/J` | Move window up / down     |
| `Mod+WheelScroll Up/Down` | Focus column left / right |

### Workspaces

| Keys                     | Action                             |
| ------------------------ | ---------------------------------- |
| `Mod+1…9`                | Focus workspace 1–9                |
| `Mod+Shift+1…9`          | Move column to workspace 1–9       |
| `Mod+Page Up/Down`       | Focus workspace up / down          |
| `Mod+Shift+Page Up/Down` | Move column to workspace down / up |

### Layout

| Keys              | Action                      |
| ----------------- | --------------------------- |
| `Mod+R`           | Cycle preset column widths  |
| `Mod+F`           | Maximize column             |
| `Mod+Shift+F`     | Fullscreen window           |
| `Mod+-` / `Mod+=` | Shrink / grow column by 10% |

### Screenshots & recording

| Keys               | Action                            |
| ------------------ | --------------------------------- |
| `Print`            | Screenshot (interactive region)   |
| `Ctrl+Print`       | Screenshot whole screen           |
| `Alt+Print`        | Screenshot focused window         |
| `Shift+Print`      | Screen recording, region (toggle) |
| `Ctrl+Shift+Print` | Screen recording, screen (toggle) |

### Audio & media

These fire on the dedicated `XF86Audio*` keys (a laptop Fn layer typically maps
them to `Fn+F8/F9/F10` for mute / down / up). Volume and microphone go through
ashell's IPC socket (`ashell msg volume-*`, `microphone-toggle-mute`), which
draws its own OSD and works even when the screen is locked. Output volume can
reach 150 percent (`[settings] max_volume`). ashell has no transport commands,
so play, next and previous use `playerctl` over MPRIS instead.

| Keys                   | Action                | Backend      |
| ---------------------- | --------------------- | ------------ |
| `XF86AudioRaiseVolume` | Volume up             | `ashell msg` |
| `XF86AudioLowerVolume` | Volume down           | `ashell msg` |
| `XF86AudioMute`        | Mute output           | `ashell msg` |
| `XF86AudioMicMute`     | Mute microphone       | `ashell msg` |
| `XF86AudioPlay`        | Play / pause          | `playerctl`  |
| `XF86AudioNext/Prev`   | Next / previous track | `playerctl`  |

### Brightness (laptops)

Backed by ashell's brightness IPC (`ashell msg brightness-*`, kernel backlight),
which draws its own OSD.

| Keys                    | Action          |
| ----------------------- | --------------- |
| `XF86MonBrightnessUp`   | Brightness up   |
| `XF86MonBrightnessDown` | Brightness down |

### Compact-keyboard fallbacks

Keyboards without a `Print` key or media keys can still reach those actions
through the `Mod+F` row. Volume itself is left to the `XF86Audio*` keys above
(the Fn layer already emits them on `Fn+F8/F9/F10`), so only the remaining
actions are mirrored here.

| Keys      | Action                   |
| --------- | ------------------------ |
| `Mod+F4`  | Mute microphone          |
| `Mod+F5`  | Play / pause             |
| `Mod+F6`  | Previous track           |
| `Mod+F7`  | Next track               |
| `Mod+F8`  | Screenshot (region)      |
| `Mod+F9`  | Screenshot screen        |
| `Mod+F10` | Screenshot window        |
| `Mod+F11` | Screen recording, region |
| `Mod+F12` | Screen recording, screen |

---

## How niri, Kitty and tmux interact

The desktop stacks in three layers, and each owns a different scope so a
keypress is never ambiguous.

| Layer | Owns                                          | Leading key                  |
| ----- | --------------------------------------------- | ---------------------------- |
| niri  | Monitors, workspaces, windows, global hotkeys | `Mod` (Super)                |
| kitty | Terminal window, tabs, native splits          | `Ctrl+Shift` / `Shift+Arrow` |
| tmux  | Sessions, windows, panes inside a terminal    | `Ctrl+a` prefix              |

In day-to-day use the flow is top-down: niri launches a Kitty window with
`Mod+Return`, and tmux comes up inside that terminal for sessions and panes.
Because niri leads with `Mod`, Kitty leads with `Ctrl+Shift`, and tmux goes
through its `Ctrl+a` prefix, the three key spaces never collide; a shortcut is
always handled by exactly one layer.

In practice the responsibilities split cleanly: niri arranges windows on screen,
tmux does the in-terminal pane work, and Kitty sits in between providing the
window itself plus modern features (true color, clipboard, prompt jumping). For
the terminal half of this story in detail, see
[Kitty + tmux](kitty-tmux.md).
