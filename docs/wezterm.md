# Wezterm Configuration & Workflows

## Overview

Wezterm serves as the foundation of the terminal stack. It is the GPU-accelerated terminal emulator responsible for rendering fonts, colors, and handling system-level keybindings (like native window/tab management and Kitty-like splits).

- **Theme:** Catppuccin Mocha (with Kitty-style overrides)
- **Font:** JetBrainsMono Nerd Font Mono @ 11pt
- **Padding:** 8px on all sides
- **Opacity:** 90% (Window transparency enabled)

## Keybindings (Kitty-Inspired)

The Wezterm configuration uses a modifier chord of `Ctrl + Shift` for almost all native operations, ensuring it doesn't conflict with shell tools or multiplexers like Zellij.

### Tabs (Wezterm Windows)

Wezterm tabs are ideal for completely separate contexts (e.g., local shell vs SSH session).

| Action          | Shortcut                   | Notes                                            |
| --------------- | -------------------------- | ------------------------------------------------ |
| New Tab         | `Ctrl + Shift + T`         |                                                  |
| Rename Tab      | `Ctrl + Shift + Alt + T`   | Prompts for a new name at the top of the window. |
| Next Tab        | `Ctrl + Shift + PageDown`  |                                                  |
| Previous Tab    | `Ctrl + Shift + PageUp`    |                                                  |
| Jump to Tab 1-4 | `Ctrl + Shift + 1` ... `4` |                                                  |

### Splits (Local Panes)

Wezterm's native splits are useful for quick, transient side-by-side work where session persistence is not required.

| Action         | Shortcut                    | Notes                                                 |
| -------------- | --------------------------- | ----------------------------------------------------- |
| Split Down     | `Ctrl + Shift + N`          | Equivalent to Kitty's horizontal split.               |
| Split Right    | `Ctrl + Shift + \|`         | Equivalent to Kitty's vertical split.                 |
| Navigate Panes | `Ctrl + Shift + Arrow Keys` | Moves focus around the splits.                        |
| Toggle Zoom    | `Ctrl + Shift + F`          | Zooms the current pane to full screen (Stack Layout). |

### Navigation & Search

| Action                 | Shortcut             | Notes                                                 |
| ---------------------- | -------------------- | ----------------------------------------------------- |
| Project Picker         | `Ctrl + Shift + P`   | Fuzzy-find and jump to configured git repositories.   |
| Quick Select Nix Path  | `Ctrl + Shift + S`   | Rapidly select and copy `/nix/store` paths on screen. |
| Scroll to Prompt (Up)  | `Shift + UpArrow`    | Jump to the previous shell prompt (OSC 133).          |
| Scroll to Prompt (Down)| `Shift + DownArrow`  | Jump to the next shell prompt (OSC 133).              |

## Smart Features

### Nix Store Integration
- **Hyperlinks:** Any `/nix/store` path visible in the terminal is automatically hyperlinked. **Ctrl + Click** (or Shift + Click) a path to open it immediately in a new `yazi` tab.
- **Quick Select:** `Ctrl + Shift + S` activates a selection mode specifically tuned to capture Nix store hashes and paths.

### Tab Bar & Icons
The tab bar mimics Kitty's bottom powerline style with enhanced visibility:
- **Process Icons:** Shows Nerd Font icons for common tools (󱄅 Nix, 󰚀 Helix, 󰒍 SSH, 󰇥 Yazi).
- **Context Coloring:** Tabs dynamically change background color based on the active process:
  - **SSH Sessions:** Rosewater/Peach background for high visibility.
  - **Sudo / Root:** Red background to indicate elevated privileges.
- **Directory Tracking:** Shows the current working directory's basename (or `~` for Home).
