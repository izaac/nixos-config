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

---

## Keybindings

### Apps & session

| Keys          | Action                                  |
| ------------- | --------------------------------------- |
| `Mod+Return`  | Launch Kitty (terminal)                 |
| `Mod+D`       | App launcher (Noctalia)                 |
| `Alt+Space`   | App launcher (Moonlight-friendly alias) |
| `Mod+E`       | File manager (nemo)                     |
| `Mod+B`       | Browser (brave-origin)                  |
| `Mod+S`       | Control center (Noctalia)               |
| `Mod+V`       | Clipboard history (Noctalia)            |
| `Mod+Ctrl+L`  | Lock screen (Noctalia)                  |
| `Mod+Shift+P` | Session panel (Noctalia)                |
| `Mod+Shift+N` | Toggle do-not-disturb (Noctalia)        |
| `Mod+Q`       | Close window                            |
| `Mod+Shift+E` | Quit niri (no confirmation)             |

### Direct power actions

| Keys               | Action    |
| ------------------ | --------- |
| `Mod+Ctrl+Shift+S` | Suspend   |
| `Mod+Ctrl+Shift+R` | Reboot    |
| `Mod+Ctrl+Shift+Q` | Power off |

### Idle & lock

Noctalia locks the screen after 10 minutes idle. Screen power (DPMS) and
suspend are left untouched, so there is no idle autosuspend; suspend stays a
manual action (`Mod+Ctrl+Shift+S`). Unlock with a YubiKey touch or your
password. Manual lock is `Mod+Ctrl+L`.

### Wallpaper & theming

Noctalia draws the wallpaper itself (the old `swaybg` daemon is gone). It scans
`~/Pictures/Wallpapers`, an out-of-store symlink to the `~/repos/wallpapers`
git checkout, so adding images needs no rebuild. Switch backgrounds live from
the control center (`Mod+S`) or with `noctalia msg wallpaper-random`.

The Noctalia shell palette is generated from the current wallpaper
(`[theme] source = "wallpaper"`, `wallpaper_scheme = "m3-tonal-spot"`), so the
bar, panels, launcher, and lock screen recolor whenever the wallpaper changes.
Stylix still owns application colors (see [kitty](kitty.md), [tmux](tmux.md)),
so terminals and GTK apps stay on the static Catppuccin Mocha palette; only
Noctalia's own surfaces follow the wallpaper.

### Focus & move

| Keys                      | Action                    |
| ------------------------- | ------------------------- |
| `Mod+←/→` or `Mod+H/L`    | Focus column left / right |
| `Mod+↑/↓` or `Mod+K/J`    | Focus window up / down    |
| `Mod+Shift+←/→` or `+H/L` | Move column left / right  |
| `Mod+Shift+↑/↓` or `+K/J` | Move window up / down     |
| `Mod+WheelScroll Up/Down` | Focus column left / right |

### Workspaces

| Keys               | Action                       |
| ------------------ | ---------------------------- |
| `Mod+1…9`          | Focus workspace 1–9          |
| `Mod+Shift+1…9`    | Move column to workspace 1–9 |
| `Mod+Page Up/Down` | Focus workspace up / down    |

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
them to `Fn+F8/F9/F10` for mute / down / up). They call Noctalia's native IPC
(`noctalia msg volume-*`, `mic-mute`, `media *`), which shows its own OSD and
works even when the screen is locked. Output volume can reach 150 percent
(`[audio] enable_overdrive`).

| Keys                   | Action                |
| ---------------------- | --------------------- |
| `XF86AudioRaiseVolume` | Volume up             |
| `XF86AudioLowerVolume` | Volume down           |
| `XF86AudioMute`        | Mute output           |
| `XF86AudioMicMute`     | Mute microphone       |
| `XF86AudioPlay`        | Play / pause          |
| `XF86AudioNext/Prev`   | Next / previous track |

### Brightness (laptops)

Backed by Noctalia's native brightness IPC (`noctalia msg brightness-*`, kernel
backlight), which draws its own OSD.

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
