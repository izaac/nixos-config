# mpv Media Player

> **Hosts**: Linux (`ninja`, `windy`)
> **Defined in**: [`home/mpv.nix`](../home/mpv.nix), `programs.mpv`
> **Imported in**: [`home/desktop.nix`](../home/desktop.nix)

[mpv](https://mpv.io/) is the primary media player across all Linux desktop environments. It is managed declaratively via Home Manager, complete with GPU acceleration, custom scripts for UI/MPRIS, and dedicated Vim-style keybindings.

---

## Hardware & Performance Configuration

mpv is tuned for zero-latency, high-quality video playback on modern Vulkan and NVIDIA/Intel hardware.

| Setting               | Value                        | Description                                        |
| --------------------- | ---------------------------- | -------------------------------------------------- |
| **Profile**           | `gpu-hq`                     | High-quality rendering profile with modern scalers |
| **GPU API**           | `vulkan`                     | High-performance Vulkan backend                    |
| **Video Output**      | `gpu-next`                   | Modern libplacebo-based renderer                   |
| **Hardware Decoding** | `auto-safe`                  | Hardware-accelerated decoding (VA-API / NVDEC)     |
| **Audio Pitch**       | `true`                       | Pitch correction on playback speed adjustment      |
| **Demuxer Cache**     | `512MiB` max / `128MiB` back | High-capacity buffer for network/local streaming   |
| **OSD Style**         | Minimal / `uosc`             | Native osd-bar disabled in favor of `uosc` OSC     |

---

## Scripts & Extensions

The setup bundles three essential mpv scripts:

1. **`uosc`** ([`pkgs.mpvScripts.uosc`](https://github.com/tomasklaen/uosc)): Modern, minimal UI replacement for the default OSC with smooth timeline controls.
2. **`mpris`** ([`pkgs.mpvScripts.mpris`](https://github.com/tumpay/mpv-mpris)): Exposes mpv controls over MPRIS2, allowing media keys, lock screen controls, and `playerctl` / the `ashell` status bar to control playback.
3. **`thumbfast`** ([`pkgs.mpvScripts.thumbfast`](https://github.com/po5/thumbfast)): On-hover thumbnail previews on the timeline seek bar.

---

## Keybindings

Keybinds use direct single keys (Vim-style `hjkl` for seek and volume) without modifiers. Because mpv receives window focus under [Niri](niri.md), these keybinds are scoped strictly inside the mpv window.

### Playback & Seeking

| Keys                | Action                                 |
| ------------------- | -------------------------------------- |
| `Space`             | Toggle play / pause                    |
| `h` / `l`           | Seek backward / forward **5 seconds**  |
| `H` / `L`           | Seek backward / forward **30 seconds** |
| `Ctrl+h` / `Ctrl+l` | Seek backward / forward **60 seconds** |
| `,` / `.`           | Previous / next playlist item          |
| `<` / `>`           | Previous / next chapter                |
| `q`                 | Quit mpv                               |
| `Q`                 | Quit mpv and save watch position       |

### Volume & Audio

| Keys      | Action                          |
| --------- | ------------------------------- |
| `k` / `j` | Volume up / down (**2%** steps) |
| `m`       | Toggle mute                     |

### Playback Speed & Subtitles

| Keys        | Action                               |
| ----------- | ------------------------------------ |
| `[` / `]`   | Decrease / increase speed by **10%** |
| `Backspace` | Reset speed to **1.0x**              |
| `s`         | Toggle subtitle visibility           |
| `S`         | Cycle available subtitle tracks      |

### Window, Navigation & Screenshots

| Keys           | Action                                                |
| -------------- | ----------------------------------------------------- |
| `f`            | Toggle fullscreen                                     |
| `o`            | Show playback progress                                |
| `O` / `Ctrl+o` | Open `uosc` in-player **file browser**                |
| `P`            | Open `uosc` **playlist browser**                      |
| `C`            | Open `uosc` **chapter list**                          |
| `Menu`         | Open full `uosc` menu                                 |
| `i`            | Toggle technical stats (codecs, FPS, drop frames)     |
| `p`            | Take screenshot (`~/Pictures/Screenshots/mpv-...png`) |

---

## Keybinding Hierarchy & Overlap Audit

mpv sits cleanly within the overall desktop hotkey system without key binding collisions:

```text
┌──────────────────────────────────────────────────────────────────┐
│ Global WM (Niri): Mod+Return, Mod+B, Mod+E, Mod+Q               │
│ ┌──────────────────────────────────────────────────────────────┐ │
│ │ Terminal (Kitty): Ctrl+Shift+t, Ctrl+Shift+n, Ctrl+Shift+f   │ │
│ │ ┌──────────────────────────────────────────────────────────┐ │ │
│ │ │ Multiplexer (tmux): Ctrl+a prefix, Ctrl+h/j/k/l (nav)    │ │ │
│ │ │ ┌──────────────────────────────────────────────────────┐ │ │ │
│ │ │ │ Editor (LazyVim): <space> leader, h/j/k/l           │ │ │ │
│ │ │ └──────────────────────────────────────────────────────┘ │ │ │
│ │ └──────────────────────────────────────────────────────────┘ │ │
│ └──────────────────────────────────────────────────────────────┘ │
│ ┌──────────────────────────────────────────────────────────────┐ │
│ │ Media Player (mpv): Direct focused keys (h/j/k/l, space, q) │ │
│ └──────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

### Overlap Matrix

- **Niri Compositor** ([`docs/niri.md`](niri.md)): Uses `Mod` (**Super** key) for all global window and workspace operations. mpv keybinds use no `Mod` key, so `Mod+Q` (close) or `Mod+F` (maximize column) pass to Niri without interference.
- **Terminal & Multiplexer** ([`docs/kitty.md`](kitty.md), [`docs/tmux.md`](tmux.md)): Kitty uses `Ctrl+Shift` and tmux uses `Ctrl+a`. mpv is a standalone GUI window, so terminal/multiplexer shortcuts do not conflict.
- **Editor** ([`docs/lazyvim.md`](lazyvim.md)): While mpv adopts Vim navigation keys (`h/j/k/l`), they operate only when the mpv window holds X11/Wayland input focus.
- **Capture Card Wrapper** ([`home/capture-card.nix`](../home/capture-card.nix)): Uses mpv CLI flags (`--profile=low-latency --untimed`) which extend the core declarative configuration seamlessly.
