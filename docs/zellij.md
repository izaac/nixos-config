# Zellij Configuration & Workflows

## Overview

Zellij is the primary terminal multiplexer, replacing `tmux`. It provides session persistence, robust layout management, and an organized way to handle complex development environments.

The configuration has been heavily customized to feel like a traditional Vim/Tmux setup, removing visual clutter (no pane frames, simplified UI) and enforcing a `Ctrl-a` prefix.

- **Theme:** Catppuccin integration via Home Manager.
- **Layout:** Compact default layout, with automatic layout resizing.
- **UI:** No pane frames, no startup tips, native mouse support, and copy-on-select enabled.
- **Persistence:** Session serialization is enabled, meaning workspaces survive terminal crashes or detaches.

## Core Navigation & Tmux Mode

All multiplexer actions are gated behind the prefix key.

**Prefix Key:** `Ctrl + a` (Replaces default `Ctrl + b`)

Once the prefix is hit, Zellij enters `Tmux` mode. You then press the following keys to execute the action and automatically return to `Normal` mode.

### Pane Management (Splits)

Requires hitting `Ctrl + a` first.

| Action      | Shortcut | Notes                                                      |
| ----------- | -------- | ---------------------------------------------------------- |
| Split Right | `\`      | Matches standard `tmux` vertical split (side-by-side).     |
| Split Down  | `v`      | Matches standard `tmux` horizontal split (top-and-bottom). |
| Close Pane  | `x`      |                                                            |
| Rename Pane | `$`      | Enters Pane Rename mode.                                   |

### Vim-Style Navigation

Requires hitting `Ctrl + a` first.

| Action      | Shortcut |
| ----------- | -------- |
| Focus Left  | `h`      |
| Focus Down  | `j`      |
| Focus Up    | `k`      |
| Focus Right | `l`      |

### Tab Management (Zellij Windows)

Requires hitting `Ctrl + a` first.

| Action          | Shortcut   | Notes                                                                     |
| --------------- | ---------- | ------------------------------------------------------------------------- |
| New Tab         | `c`        |                                                                           |
| Next Tab        | `n`        |                                                                           |
| Previous Tab    | `p`        |                                                                           |
| Close Tab       | `&`        |                                                                           |
| Rename Tab      | `,`        | Enters Tab Rename mode.                                                   |
| Toggle Last Tab | `Ctrl + a` | Hit `Ctrl + a` twice rapidly to bounce between your two most recent tabs. |

### Session Management

| Action         | Shortcut       | Notes                                                             |
| -------------- | -------------- | ----------------------------------------------------------------- |
| Detach Session | `Prefix` + `d` | Leaves the session running in the background.                     |
| Send Prefix    | `Prefix` + `a` | Useful if you are SSH'd into another machine running Zellij/Tmux. |

## Other Zellij Features

While the Tmux mode is the primary way of interacting, Zellij's built-in modes are still accessible if needed.

- **Layouts:** Managed automatically via `auto_layout = true` and `default_layout = "compact"`.
