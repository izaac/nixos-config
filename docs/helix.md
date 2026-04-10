# Helix Configuration & Workflows

## Overview

Helix is the primary code editor, replacing Neovim/LazyVim. It is a post-modern modal editor with built-in LSP support, tree-sitter syntax highlighting, multi-cursor editing, and a fuzzy picker — all without plugins or external package managers.

The configuration is managed entirely through Home Manager (`home/helix.nix`), which generates `config.toml` and `languages.toml` declaratively. All language servers and formatters are provided by Nix.

- **Theme:** Catppuccin Mocha (auto-applied via Home Manager integration).
- **Font:** Inherited from Wezterm (JetBrainsMono Nerd Font Mono @ 11pt).
- **UI:** Relative line numbers, cursor-line highlight, color-coded modes, indent guides, buffer tabs, and soft-wrap.
- **Auto-save:** Enabled. Files are saved automatically on focus loss.
- **Auto-format:** Enabled globally. Files are formatted on save via the configured formatter for each language.

## Keybindings

Helix is modal like Vim, but uses a **selection → action** model instead of Vim's **verb → object**. You select text first, then act on it.

### Modes

The cursor shape changes per mode for visual feedback:

| Mode   | Cursor        | Enter with |
| ------ | ------------- | ---------- |
| Normal | `█` block     | `Escape`   |
| Insert | `│` bar       | `i`        |
| Select | `▁` underline | `v`        |

### Custom Keybindings

These are additions on top of Helix's defaults:

| Action           | Shortcut | Mode   | Notes                             |
| ---------------- | -------- | ------ | --------------------------------- |
| Save file        | `Ctrl+s` | Normal | Also works in Insert mode.        |
| Focus pane left  | `Ctrl+h` | Normal | Matches Vim/Zellij muscle memory. |
| Focus pane down  | `Ctrl+j` | Normal |                                   |
| Focus pane up    | `Ctrl+k` | Normal |                                   |
| Focus pane right | `Ctrl+l` | Normal |                                   |

### Built-in Space Menu

Press `Space` in Normal mode to open the which-key popup. Key commands:

| Action                  | Shortcut    | Notes                                           |
| ----------------------- | ----------- | ----------------------------------------------- |
| File picker             | `Space + f` | Fuzzy search all files (respects `.gitignore`). |
| Buffer picker           | `Space + b` | Switch between open files.                      |
| Symbol picker           | `Space + s` | Jump to symbols in the current file (LSP).      |
| Workspace symbol picker | `Space + S` | Jump to symbols across the project.             |
| Diagnostics             | `Space + d` | Errors and warnings in the current file.        |
| Workspace diagnostics   | `Space + D` | All errors and warnings across the project.     |
| Code action             | `Space + a` | Quick fixes, refactors (LSP).                   |
| Rename symbol           | `Space + r` | Project-wide rename (LSP).                      |
| Hover docs              | `Space + k` | Inline documentation popup.                     |
| Global search           | `Space + /` | Grep across the project.                        |
| Command palette         | `Space + ?` | Search all available commands.                  |
| Yank to clipboard       | `Space + y` | Copy selection to system clipboard.             |
| Paste from clipboard    | `Space + p` | Paste from system clipboard.                    |

### Essential Navigation

| Action                | Shortcut      | Notes                              |
| --------------------- | ------------- | ---------------------------------- |
| Go to definition      | `g d`         |                                    |
| Go to references      | `g r`         |                                    |
| Go to implementation  | `g i`         |                                    |
| Go to type definition | `g y`         |                                    |
| Go to file start/end  | `g g` / `g e` |                                    |
| Match bracket         | `m m`         | Jump to matching `()`, `{}`, `[]`. |
| Next/Prev diagnostic  | `] d` / `[ d` |                                    |
| Next/Prev git hunk    | `] g` / `[ g` | Built-in git gutter support.       |

### Multi-Cursor Editing

One of Helix's strongest features. No plugins needed.

| Action                    | Shortcut    | Notes                                   |
| ------------------------- | ----------- | --------------------------------------- |
| Add cursor below          | `C`         | Extends selection down.                 |
| Add cursor on all matches | `s`         | Select a word, then `s` to match all.   |
| Split selection by regex  | `S`         | Powerful: select a block, `S` to split. |
| Keep/Remove selections    | `K` / `A-K` | Filter selections by regex.             |
| Rotate selection contents | `A-,`       | Swap content between cursors.           |

### Window (Split) Management

Enter window mode with `Ctrl+w` or `Space + w`, then:

| Action          | Shortcut                | Notes                               |
| --------------- | ----------------------- | ----------------------------------- |
| Split right     | `Ctrl+w` then `v`       | Vertical split.                     |
| Split down      | `Ctrl+w` then `s`       | Horizontal split.                   |
| Close split     | `Ctrl+w` then `q`       |                                     |
| Navigate splits | `Ctrl+h/j/k/l`          | Direct (custom binding, no prefix). |
| Swap splits     | `Ctrl+w` then `H/J/K/L` | Moves the pane in that direction.   |

## Language Support

All language servers and formatters are bundled via Nix — nothing is installed at runtime.

### Configured Languages

| Language              | LSP                          | Formatter   | Linter     |
| --------------------- | ---------------------------- | ----------- | ---------- |
| Shell (Bash)          | bash-language-server         | shfmt       | shellcheck |
| TypeScript/JavaScript | typescript-language-server   | prettierd   | —          |
| Python                | pyright + ruff               | ruff format | ruff       |
| Nix                   | nil                          | alejandra   | —          |
| YAML                  | yaml-language-server         | —           | —          |
| Ansible               | ansible-language-server      | —           | —          |
| TOML                  | taplo                        | taplo       | —          |
| JSON                  | vscode-langservers-extracted | prettierd   | —          |
| HTML/CSS              | vscode-langservers-extracted | —           | —          |
| Markdown              | markdown-oxide               | prettierd   | —          |

### YAML Schema Store

The `yaml-language-server` is configured with schema store integration enabled. This means YAML files for known formats (Docker Compose, GitHub Actions, Kubernetes, etc.) get automatic validation and completion without any per-project configuration.

### Python Dual-Server Setup

Python uses two language servers simultaneously:

- **Pyright:** Type checking, completions, hover documentation.
- **Ruff:** Fast linting and formatting (replaces flake8, black, isort).

## Editor Behavior

| Setting         | Value              | Effect                                                       |
| --------------- | ------------------ | ------------------------------------------------------------ |
| `line-number`   | `relative`         | Shows relative line numbers for efficient Vim-style jumps.   |
| `bufferline`    | `multiple`         | Shows open file tabs when more than one buffer is open.      |
| `color-modes`   | `true`             | Statusline color changes to reflect current mode.            |
| `indent-guides` | `▏`                | Renders thin vertical lines at each indentation level.       |
| `inlay-hints`   | `true`             | Shows inline type hints from the LSP (where supported).      |
| `idle-timeout`  | `250ms`            | Completions and hover popups appear faster than the default. |
| `soft-wrap`     | `true`             | Long lines wrap visually without inserting newlines.         |
| `file-picker`   | hidden + gitignore | Shows dotfiles but respects `.gitignore`.                    |

## System-Level Fallback

Helix is the user-level editor (`EDITOR=hx`, `VISUAL=hx`). For TTY rescue and recovery scenarios, `neovim` remains installed at the system level via `modules/core/maintenance.nix` and is accessible as `nvim` from any shell.
