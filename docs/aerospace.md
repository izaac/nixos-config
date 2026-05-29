# AeroSpace (Mac tiling WM)

> **Host**: `Mac` (Apple Silicon, arm64 — a **laptop**)
> **Defined in**: [`home/darwin/aerospace.nix`](../home/darwin/aerospace.nix) — `programs.aerospace`

[AeroSpace](https://github.com/nikitabobko/AeroSpace) is an i3-like tiling window
manager for macOS. It needs **no SIP changes** and does not replace the macOS
window server — it manages window frames itself and uses its own fast virtual
workspaces instead of native macOS Spaces (no Spaces switch animation).

This is the Mac's stand-in for [niri](../home/niri.nix) on the Linux hosts. The
keybindings deliberately mirror niri so the muscle memory transfers.

---

## What it is

- A user-level tiling WM, run and supervised by a Home Manager **launchd agent**
  (`programs.aerospace.launchd.enable = true`) so it starts at login and restarts
  if it dies.
- Config is declared as Nix and rendered to AeroSpace's TOML — never edit the
  generated config by hand; edit [`home/darwin/aerospace.nix`](../home/darwin/aerospace.nix)
  and re-apply.
- Layout: tiles by default, 8px gaps (matches niri).

---

## The modifier is Alt (Option), not Cmd

niri uses `Mod` (Super). On macOS, **Cmd is reserved** by virtually every app
(Cmd+Q quit, Cmd+W close, Cmd+1-9 tab/window switch, etc.), so binding a WM to
Cmd would collide constantly. AeroSpace therefore uses **Alt (Option)**:

> niri `Mod + <key>` → AeroSpace `Alt + <key>`

Everything below reads exactly like the niri config with `Alt` swapped in for
`Mod`.

---

## Keybindings

All binds live in `mode.main`. `Alt` = Option.

| Keys                    | Action                           | niri equivalent       |
| ----------------------- | -------------------------------- | --------------------- |
| `Alt + Enter`           | Launch a new kitty window        | `Mod + Return`        |
| `Alt + Q`               | Close focused window             | `Mod + Q`             |
| `Alt + H/J/K/L`         | Focus left / down / up / right   | `Mod + H/J/K/L`       |
| `Alt + ←/↓/↑/→`         | Focus left / down / up / right   | (arrows)              |
| `Alt + Shift + H/J/K/L` | Move window left/down/up/right   | `Mod + Shift + …`     |
| `Alt + Shift + ←/↓/↑/→` | Move window left/down/up/right   | (arrows)              |
| `Alt + F`               | Fullscreen the focused window    | `Mod + F`             |
| `Alt + /`               | Tiles layout (horiz/vert)        | —                     |
| `Alt + ,`               | Accordion layout (horiz/vert)    | —                     |
| `Alt + -` / `Alt + =`   | Shrink / grow window (smart)     | `Mod + -` / `Mod + =` |
| `Alt + 1…9`             | **Switch to workspace 1…9**      | `Mod + 1…9`           |
| `Alt + Shift + 1…9`     | Move window to workspace 1…9     | `Mod + Shift + 1…9`   |
| `Alt + Tab`             | Toggle last/previous workspace   | —                     |
| `Alt + PageUp/PageDown` | Previous / next workspace (wrap) | `Mod + PageUp/Down`   |
| `Alt + Shift + ;`       | Enter **service mode**           | —                     |

### Laptop note: workspace navigation

This Mac is a laptop. The **built-in MacBook keyboard has no physical
PageUp/PageDown keys** — they are `Fn + ↑` / `Fn + ↓`. So:

- **Day-to-day workspace switching is `Alt + 1…9`** (the primary nav).
- `Alt + PageUp/PageDown` (i.e. `Alt + Fn + ↑/↓` on the laptop) mirror niri's
  `Mod + PageUp/Down` and are handy on an **external keyboard**.
- `Alt + Tab` jumps back to the previous workspace — the laptop-friendly toggle.

For a trackpad gesture like niri's, see [3-finger swipe](#optional-3-finger-swipe-between-workspaces).

### Service mode (`Alt + Shift + ;`)

Service mode is a sub-mode for housekeeping. Press `Alt + Shift + ;` to enter it,
then one key acts and returns you to normal mode:

| Key         | Action                                      |
| ----------- | ------------------------------------------- |
| `Esc`       | Reload config, then back to main            |
| `R`         | Reset / flatten the workspace layout tree   |
| `F`         | Toggle floating ⇄ tiling for focused window |
| `Backspace` | Close all windows but the focused one       |

---

## Floating window rules

Small utility windows tile badly, so they open **floating** instead of tiled
(mirrors niri's `open-floating` rules):

| App             | Why floating                   |
| --------------- | ------------------------------ |
| System Settings | Modal-style preferences window |
| Calculator      | Tiny fixed-size utility        |
| Tunnelblick     | Small VPN status windows       |

Add more in `on-window-detected` in [`home/darwin/aerospace.nix`](../home/darwin/aerospace.nix).
Find an app's `app-id` (bundle id) with:

```bash
osascript -e 'id of app "AppName"'
# or, for the frontmost window:
aerospace list-windows --focused
```

---

## First run: grant Accessibility permission

AeroSpace moves and resizes other apps' windows, so macOS requires it to be
trusted for Accessibility. **On the first launch after applying** you must:

1. Open **System Settings → Privacy & Security → Accessibility**.
2. Enable the toggle for **AeroSpace**.
3. If it does not appear, add it with `+`, or run `aerospace reload-config` after
   granting.

Until this is granted, AeroSpace runs but cannot tile windows.

---

## How to apply

AeroSpace is part of the Mac's Home Manager config. Apply it like any other
Mac change (commit + push first — flakes only see git-tracked files):

```bash
ssh izaac@192.168.0.218 'cd ~/repos/nixos-config && git pull --ff-only \
  && darwin-rebuild build --flake .#Mac \
  && sudo darwin-rebuild switch --flake .#Mac'
```

The launchd agent starts AeroSpace at the end of the switch and at every login.

---

## Practical examples

### 1. Open two terminals side by side

1. `Alt + Enter` — first kitty window (fills the screen).
2. `Alt + Enter` — second kitty window; AeroSpace tiles them automatically.
3. `Alt + H` / `Alt + L` — move focus between them.
4. `Alt + Shift + L` — swap the focused window to the right slot.

### 2. Organise work across workspaces

1. On workspace 1, open your editor (`Alt + Enter`, launch from there).
2. `Alt + 2` — jump to an empty workspace 2; open a browser.
3. `Alt + 3` — workspace 3 for chat (Slack/Telegram).
4. `Alt + 1` / `Alt + 2` / `Alt + 3` — flip between them instantly.
5. `Alt + Tab` — bounce back to the workspace you were just on.

### 3. Move a window to another workspace

Focus the window, then `Alt + Shift + 4` — the window jumps to workspace 4 and
you stay put. Press `Alt + 4` to follow it.

### 4. Temporarily float a window

A window tiling awkwardly (a dialog, a media player):

1. `Alt + Shift + ;` then `F` — toggles the focused window to floating.
2. Repeat to tile it back.

### 5. Reload after editing the config

After changing [`home/darwin/aerospace.nix`](../home/darwin/aerospace.nix) and
re-applying, reload without logging out:

```bash
aerospace reload-config
```

or `Alt + Shift + ;` then `Esc`.

### Optional: 3-finger swipe between workspaces

On a laptop the niri trackpad feel comes closest via
[SwipeAeroSpace](https://github.com/mediosz/SwipeAeroSpace) — a 3-finger swipe to
change AeroSpace workspaces (AeroSpace disables the native 3-finger Spaces swipe).
Install as a Homebrew cask (`mediosz/swipeaerospace`) and grant it Accessibility
permission too.

---

## Workflow summary

| Goal                     | Keys / command                                                         |
| ------------------------ | ---------------------------------------------------------------------- |
| New terminal             | `Alt + Enter`                                                          |
| Close window             | `Alt + Q`                                                              |
| Move focus               | `Alt + H/J/K/L` or arrows                                              |
| Move window              | `Alt + Shift + H/J/K/L`                                                |
| Switch workspace         | `Alt + 1…9` (primary), `Alt + Tab` (toggle)                            |
| Send window to workspace | `Alt + Shift + 1…9`                                                    |
| Fullscreen               | `Alt + F`                                                              |
| Reload config            | `aerospace reload-config`                                              |
| Is it running?           | `aerospace list-workspaces --focused`                                  |
| Restart the agent        | `launchctl kickstart -k gui/$(id -u)/org.nix-community.home.aerospace` |

---

## Troubleshooting

- **`Cannot connect to AeroSpace server. Is AeroSpace.app running?`** — the app
  is not running. Check the launchd agent and (re)start it:

  ```bash
  launchctl list | grep -i aerospace
  launchctl kickstart -k gui/$(id -u)/org.nix-community.home.aerospace
  ```

  If it still will not start, confirm the switch actually activated the agent
  (`darwin-rebuild switch` completed) and that **Accessibility permission** is
  granted (see [First run](#first-run-grant-accessibility-permission)).

- **Windows don't tile** — Accessibility permission is missing; grant it, then
  `aerospace reload-config`.
- **A workspace nav key does nothing** — on the laptop keyboard remember
  PageUp/PageDown are `Fn + ↑/↓`; prefer `Alt + 1…9`.
