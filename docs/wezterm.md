# Wezterm Configuration & Workflows

## Overview
Wezterm serves as the foundation of the terminal stack. It is the GPU-accelerated terminal emulator responsible for rendering fonts, colors, and handling system-level keybindings (like native window/tab management and Kitty-like splits).

- **Theme:** Catppuccin Mocha (with Kitty-style overrides)
- **Font:** JetBrainsMono Nerd Font Mono @ 11pt
- **Padding:** 10px on all sides

## Keybindings (Kitty-Inspired)
The Wezterm configuration uses a modifier chord of `Ctrl + Shift` for almost all native operations, ensuring it doesn't conflict with shell tools or multiplexers like Zellij.

### Tabs (Wezterm Windows)
Wezterm tabs are ideal for completely separate contexts (e.g., local shell vs SSH session).

| Action | Shortcut | Notes |
|--------|----------|-------|
| New Tab | `Ctrl + Shift + T` | |
| Rename Tab | `Ctrl + Shift + Alt + T` | Prompts for a new name at the top of the window. |
| Next Tab | `Ctrl + Shift + PageDown` | |
| Previous Tab | `Ctrl + Shift + PageUp` | |
| Jump to Tab 1-4| `Ctrl + Shift + 1` ... `4` | |

### Splits (Local Panes)
Wezterm's native splits are useful for quick, transient side-by-side work where session persistence is not required.

| Action | Shortcut | Notes |
|--------|----------|-------|
| Split Down | `Ctrl + Shift + N` | Equivalent to Kitty's horizontal split. |
| Split Right | `Ctrl + Shift + \|` | Equivalent to Kitty's vertical split. |
| Navigate Panes | `Ctrl + Shift + Arrow Keys` | Moves focus around the splits. |
| Toggle Zoom | `Ctrl + Shift + F` | Zooms the current pane to full screen (Stack Layout). |

## Tab Bar Behavior
The tab bar mimics Kitty's bottom powerline style.
- **Location:** Bottom of the window.
- **Tab Titles:** Automatically formatted to show the active process name and the current working directory's base name (e.g., `zsh ~` or `nvim src`).
