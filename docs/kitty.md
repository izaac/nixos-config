# Kitty Terminal

> **Hosts**: all (`ninja`, `windy` on Linux and `Mac` on Apple Silicon laptop)
> **Defined in**:
>
> - Linux: [`home/kitty.nix`](../home/kitty.nix), `programs.kitty`, themed by Stylix
> - Mac: [`home/darwin/kitty.nix`](../home/darwin/kitty.nix), raw `kitty.conf`, **no Stylix**

[Kitty](https://sw.kovidgoyal.net/kitty/) is the terminal on every host.
[`tmux`](tmux.md) runs inside it for sessions and panes, and the kitty binds
below are terminal-level and sit underneath tmux's own prefix keys. For how the
two layers split the work, see [Kitty + tmux](kitty-tmux.md).

The two hosts use **two separate config files** because the Mac needs macOS-only
workarounds (shell pinning, Option-as-Alt) and is not themed by Stylix. The
keybindings are kept in sync so muscle memory transfers, with one deliberate
divergence for the laptop keyboard (see [Mac differences](#mac-differences)).

---

## Keybindings

These are the **custom** binds defined in the config. Kitty's own defaults
(e.g. `ctrl+shift+c/v` copy/paste on Linux, `⌘C/⌘V` on macOS) still apply on top.

| Keys                          | Action                               | Linux | Mac |
| ----------------------------- | ------------------------------------ | :---: | :-: |
| `Ctrl+Shift+T`                | New tab                              |  Yes  | Yes |
| `Ctrl+Shift+X`                | Close tab                            |  Yes  | Yes |
| `⌘W`                          | Close tab (Mac)                      |  No   | Yes |
| `Ctrl+Shift+1…4`              | Go to tab 1–4                        |  Yes  | Yes |
| `Ctrl+Shift+PageUp/PageDown`  | Previous / next tab                  |  Yes  | Yes |
| `Ctrl+Tab` / `Ctrl+Shift+Tab` | Next / previous tab (laptop cycle)   |  No   | Yes |
| `Ctrl+Shift+N`                | Split horizontally (`hsplit`)        |  Yes  | Yes |
| `Ctrl+Shift+\`                | Split vertically (`vsplit`)          |  Yes  | Yes |
| `Ctrl+Shift+←/→/↑/↓`          | Move focus between splits            |  Yes  | Yes |
| `Ctrl+Shift+F`                | Toggle zoom (`stack` layout)         |  Yes  | Yes |
| `Shift+↑` / `Shift+↓`         | Jump to previous / next shell prompt |  Yes  | Yes |

Splits and the zoom toggle require `enabled_layouts splits,stack` (set in both
configs). `Shift+↑/↓` prompt-jumping relies on kitty **shell integration** being
active (enabled on Linux, loaded manually on the Mac, see below).

### Useful kitty defaults

| Linux                  | Mac   | Action                       |
| ---------------------- | ----- | ---------------------------- |
| `Ctrl+Shift+C`         | `⌘C`  | Copy                         |
| `Ctrl+Shift+V`         | `⌘V`  | Paste                        |
| `Ctrl+Shift+=`         | `⌘+`  | Increase font size           |
| `Ctrl+Shift+-`         | `⌘-`  | Decrease font size (session) |
| `Ctrl+Shift+Backspace` | `⌘0`  | Reset font size              |
| `Ctrl+Shift+F5`        | `⌃⌘,` | Reload `kitty.conf`          |

---

## Mac differences

The Mac config diverges from the Linux one in a few deliberate ways:

| Area             | Linux (`home/kitty.nix`)                                    | Mac (`home/darwin/kitty.nix`)                                           |
| ---------------- | ----------------------------------------------------------- | ----------------------------------------------------------------------- |
| **Theming**      | Stylix → Catppuccin Mocha, JetBrainsMono Nerd Font, size 13 | **Not themed** (Stylix off); kitty defaults + `font_size 14`            |
| **Shell**        | Default `$SHELL`                                            | Pinned to the nix `zsh --login` (see below)                             |
| **Shell integ.** | `shellIntegration.mode = "enabled"`                         | `shellIntegration.mode = "enabled"` (kitty auto-detects zsh)            |
| **Option key**   | n/a                                                         | `macos_option_as_alt yes` so Option+Arrow word-motion works             |
| **Close/quit**   | `confirm_os_window_close = 0`                               | `confirm_os_window_close -1` + `macos_quit_when_last_window_closed yes` |
| **Tab cycle**    | PageUp/PageDown only                                        | **adds `Ctrl+Tab` / `Ctrl+Shift+Tab`** (laptop, no PageUp/Down keys)    |
| **Look**         | 0.90 opacity, 8px padding, powerline tab bar                | `background_opacity 0.90` (matches ninja); padding/tab-bar left default |

### Why the Mac pins the shell

The macOS GUI launchd session can leave `$SHELL` pointing at a stale login shell
(e.g. the system `/bin/zsh` or an old `/bin/bash`), so a fresh kitty window would
not pick up the nix-managed shell. The Mac config therefore pins kitty to the nix
`zsh` with `--login` so it reads `.zprofile` → `.zshrc` from the managed
environment.

Because kitty detects `zsh` by basename, `shellIntegration.mode = "enabled"`
injects its shell integration automatically (the `KITTY_*` env vars and prompt
marking). With integration live, kitty can tell an idle prompt from a running
command, which is what makes `confirm_os_window_close -1` only warn on close when
a job is actually running.

### Why no PageUp/PageDown on the Mac

The built-in MacBook keyboard has **no physical PageUp/PageDown keys** (they are
`Fn+↑` / `Fn+↓`). The PageUp/PageDown tab binds are kept for an external
keyboard, but the day-to-day tab cycle is `Ctrl+Tab` / `Ctrl+Shift+Tab`.

---

## Changing the font size

- **Linux**: font comes from Stylix, not kitty. Edit `stylix.fonts.sizes.terminal`
  in [`modules/core/theme.nix`](../modules/core/theme.nix) and rebuild.
- **Mac**: edit `font_size` in [`home/darwin/kitty.nix`](../home/darwin/kitty.nix)
  and re-apply. For a quick, non-persistent change use `⌘+` / `⌘-` / `⌘0`.

---

## How to apply

### Linux (`ninja` / `windy`)

```bash
just build      # nh os switch .
```

Reload an open window after a config change with `Ctrl+Shift+F5`.

### Mac

Flakes only see git-tracked files, so commit + push first, then:

```bash
ssh izaac@192.168.0.218 'cd ~/repos/nixos-config && git pull --ff-only \
  && darwin-rebuild build --flake .#Mac \
  && sudo darwin-rebuild switch --flake .#Mac'
```

Open kitty windows keep the old config until reloaded, so press `⌃⌘,` or open a
new window. See [AeroSpace → How to apply](aerospace.md#how-to-apply) for the
full remote workflow.
