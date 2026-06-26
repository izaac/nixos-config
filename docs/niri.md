# Niri Compositor

> **Hosts**: Linux (`ninja`, `windy`)
> **Defined in**: [`home/niri.nix`](../home/niri.nix), `programs.niri.settings`

[Niri](https://github.com/YaLTeR/niri) is the scrollable-tiling Wayland
compositor on both Linux hosts, wired in through
[niri-flake](https://github.com/sodiboo/niri-flake). It owns the outermost layer
of the desktop: monitors, workspaces, windows and global hotkeys. The terminal
stack ([Kitty](kitty.md) with [tmux](tmux.md) inside it) lives one level down,
launched by niri and never competing for the same keys — see
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
| `Mod+D`       | App launcher (fuzzel)                   |
| `Alt+Space`   | App launcher (Moonlight-friendly alias) |
| `Mod+E`       | File manager (nemo)                     |
| `Mod+B`       | Browser (brave-origin)                  |
| `Mod+S`       | Audio sink menu                         |
| `Mod+V`       | Clipboard history (cliphist + fuzzel)   |
| `Mod+Ctrl+L`  | Lock screen                             |
| `Mod+Shift+P` | Power menu (wlogout)                    |
| `Mod+Shift+N` | Toggle do-not-disturb (mako)            |
| `Mod+Q`       | Close window                            |
| `Mod+Shift+E` | Quit niri (no confirmation)             |

### Direct power actions

| Keys               | Action    |
| ------------------ | --------- |
| `Mod+Ctrl+Shift+S` | Suspend   |
| `Mod+Ctrl+Shift+R` | Reboot    |
| `Mod+Ctrl+Shift+Q` | Power off |

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
them to `Fn+F8/F9/F10` for mute / down / up). Volume changes show a single
replacing mako OSD bubble and work even when the screen is locked.

| Keys                   | Action                |
| ---------------------- | --------------------- |
| `XF86AudioRaiseVolume` | Volume up             |
| `XF86AudioLowerVolume` | Volume down           |
| `XF86AudioMute`        | Mute output           |
| `XF86AudioMicMute`     | Mute microphone       |
| `XF86AudioPlay`        | Play / pause          |
| `XF86AudioNext/Prev`   | Next / previous track |

### Brightness (laptops)

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

### Host-specific (`ninja` only)

| Keys          | Action                                        |
| ------------- | --------------------------------------------- |
| `Mod+M`       | Focus the Sunshine dummy monitor (`HDMI-A-1`) |
| `Mod+Shift+M` | Move column to the Sunshine dummy monitor     |

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
through its `Ctrl+a` prefix, the three key spaces never collide — a shortcut is
always handled by exactly one layer.

In practice the responsibilities split cleanly: niri arranges windows on screen,
tmux does the in-terminal pane work, and Kitty sits in between providing the
window itself plus modern features (true color, clipboard, prompt jumping). For
the terminal half of this story in detail, see
[Kitty + tmux](kitty-tmux.md).
