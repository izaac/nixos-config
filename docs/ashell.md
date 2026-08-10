# ashell Desktop Shell

> **Host**: `ninja` only
> **Defined in**: [`home/ashell.nix`](../home/ashell.nix)
> **Niri integration**: [`home/niri.nix`](../home/niri.nix) (shared binds), ashell.nix (shell-specific binds)

[ashell](https://github.com/MalpenZibo/ashell) is the status bar and desktop
shell on `ninja`. On `windy`, the same role is filled by
[Noctalia](https://github.com/noctalia-dev/noctalia); see `home/noctalia.nix`.

## Bar Layout

```text
┌─────────────────────────────────────────────────────────────────────────┐
│ 󱗼  󰸉  Workspaces │      %a %d %b %R      │ ♫  CPU/Mem  ⏺  📋 🔔 🔒 ⚙  │
│   left             │       center           │           right           │
└─────────────────────────────────────────────────────────────────────────┘
```

| Position   | Modules                                                                                  |
| ---------- | ---------------------------------------------------------------------------------------- |
| **Left**   | `appLauncher` (fuzzel), `wallpaper` (picker), `Workspaces`                               |
| **Center** | `Tempo` (clock: `%a %d %b %R`)                                                           |
| **Right**  | `MediaPlayer`, `SystemInfo`, `Tray`, `clipboard`, `Notifications`, `Privacy`, `Settings` |

### Custom Modules

Three bar modules are custom buttons defined in `ashell.nix`:

| Module        | Icon | Action                                 |
| ------------- | ---- | -------------------------------------- |
| `appLauncher` | 󱗼    | Spawns `fuzzel`                        |
| `wallpaper`   | 󰸉    | Runs `set-wallpaper pick`              |
| `clipboard`   | 󰅇    | Runs `clipboard-menu` (stash + fuzzel) |

## IPC Commands

ashell exposes an IPC socket for volume and brightness control with built-in OSD.
Media transport has no IPC equivalent and goes through `playerctl` instead.

| Command                             | Action                       |
| ----------------------------------- | ---------------------------- |
| `ashell msg volume-up`              | Raise volume (OSD shown)     |
| `ashell msg volume-down`            | Lower volume (OSD shown)     |
| `ashell msg volume-toggle-mute`     | Toggle output mute           |
| `ashell msg microphone-toggle-mute` | Toggle mic mute              |
| `ashell msg brightness-up`          | Raise brightness (OSD shown) |
| `ashell msg brightness-down`        | Lower brightness (OSD shown) |

Volume can reach 150% (`max_volume = 150`). Step size is 5%.

### What ashell IPC does NOT have

- No `toggle-control-center` or `toggle-notifications`: these panels are
  click-only on the bar icons. No keybind possible until upstream adds IPC.
- No media transport: `playerctl` handles play/pause/next/prev over MPRIS.

## Dynamic Theming (matugen)

ashell's colors are derived from the current wallpaper using
[matugen](https://github.com/InioX/matugen) (Material You color generation):

```text
Wallpaper image
    │
    ▼
matugen (scheme-tonal-spot, dark mode)
    │
    ▼
~/.config/matugen/templates/ashell.toml  (Nix-managed template)
    │
    ▼
~/.config/ashell/config.toml  (matugen output, ashell hot-reloads)
```

The template contains the full ashell configuration with `{{colors.*}}` placeholders
in the `[appearance]` section. Everything except colors is declarative and
reviewable in git. ashell watches `config.toml` and hot-reloads on change.

**Semantic colors** (`success`, `warning`, `danger`) are pinned to the static
Catppuccin/Stylix palette (`base0B`, `base0A`, `base08`) rather than derived from
the wallpaper, because a wallpaper-derived "danger" could come out green.

Home Manager re-renders `config.toml` on every activation (`home.activation.renderAshellConfig`),
so a rebuild that changes the template applies immediately without waiting for a
wallpaper change.

## Session Wrapper

niri's `spawn-at-startup` launches `ashell-session`, not `ashell` directly.
The wrapper manages the full shell lifecycle:

1. Acquires a `flock` guard (`$XDG_RUNTIME_DIR/ashell-session.lock`), which prevents
   dual-bar races when `KillUserProcesses=false` lets a previous session linger.
2. Starts `awww-daemon` (wallpaper renderer) and waits for it to be ready.
3. Restores the last wallpaper from `~/.local/state/current-wallpaper` (or falls
   back to the Stylix default).
4. Supervises `ashell` in a loop:
   - Crash → restart after 2 seconds.
   - 5 rapid crashes (< 30s each) → give up with `notify-send` alert.
   - Compositor gone (`NIRI_SOCKET` vanished) → exit cleanly.

To restart ashell by hand, kill the `ashell` process and the wrapper brings it back.

## Settings Panel

The settings module groups system indicators into a single expandable panel:

| Indicator       | Notes                                       |
| --------------- | ------------------------------------------- |
| `IdleInhibitor` | Toggle caffeine mode                        |
| `PowerProfile`  | Performance / balanced / power-saver        |
| `Audio`         | Output volume slider, sink selection        |
| `Microphone`    | Input volume, source selection              |
| `Bluetooth`     | Device list                                 |
| `Network`       | WiFi list (NetworkManager hosts only)       |
| `Vpn`           | VPN connections (NetworkManager hosts only) |
| `Battery`       | Charge level (laptops only, not on ninja)   |
| `Brightness`    | Backlight slider (laptops only)             |

The panel also exposes lock, logout, suspend, reboot, and shutdown actions.

## System Info

The `SystemInfo` module shows CPU, memory, and temperature with configurable
warning/alert thresholds:

| Metric      | Warn    | Alert   | Interval |
| ----------- | ------- | ------- | -------- |
| CPU         | 60%     | 80%     | 5s       |
| Memory      | 70%     | 85%     | 5s       |
| Temperature | default | default | 5s       |

## OSD (On-Screen Display)

Volume and brightness changes via IPC show a percentage overlay:

- Timeout: 1500ms
- Shows percentage for both volume and brightness

## Overlay and Network Patch

ashell is pinned to `nixpkgs-unstable` via `overlays/ashell-unstable.nix` because
the 26.05 stable channel lacks IPC and OSD support.

The overlay also carries `overlays/patches/ashell-network-backoff.patch`, which
adds exponential backoff to the NetworkManager service backend. Without it, on a
host running `systemd-networkd` (like `ninja`), the backend retries every 5 seconds
forever, roughly 17k D-Bus round trips and 3 MB of log per day. The patch parks
the service after 6 failed attempts.

> **Maintenance**: Re-check the patch against `src/services/network/mod.rs` on
> every ashell version bump.

## Screencast Privacy

Niri layer rules block sensitive content from screen captures:

| Layer                | Hidden From |
| -------------------- | ----------- |
| `ashell-toast-layer` | Screencast  |
| `clipboard-menu`     | Screencast  |

The clipboard menu renders plaintext history (potentially including passwords),
so it gets its own namespace and layer rule separate from fuzzel's default.
