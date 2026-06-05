# tmux

> **Hosts**: all (`ninja`, `windy` on Linux, `Mac` on Apple Silicon)
> **Defined in**: [`home/tmux.nix`](../home/tmux.nix), `programs.tmux`, themed by Stylix

[tmux](https://github.com/tmux/tmux) is the terminal multiplexer on every host.
It runs inside [Kitty](kitty.md) and owns sessions, windows and panes, while the
Kitty keybinds sit at the terminal level underneath tmux's own prefix. For the
details of how the two layers cooperate, see [Kitty + tmux](kitty-tmux.md).

Colors come from Stylix (Catppuccin Mocha, set in
[`modules/core/theme.nix`](../modules/core/theme.nix)). Turning on
`programs.tmux` is enough for Stylix to paint the status bar and panes, so there
is no manual Catppuccin block in the config. Only the status-bar layout is set by
hand.

The module loads on all hosts through
[`modules/core/home-manager.nix`](../modules/core/home-manager.nix) on Linux and
directly from [`hosts/Mac/configuration.nix`](../hosts/Mac/configuration.nix) on
the Mac.

## Core behavior

| Setting            | Value           | Why                                           |
| ------------------ | --------------- | --------------------------------------------- |
| **Prefix**         | `Ctrl+a`        | Replaces the default `Ctrl+b`, easier reach   |
| `baseIndex`        | `1`             | Windows and panes start at 1, not 0           |
| `escapeTime`       | `0`             | No delay, so `Esc` in Vim or Helix is instant |
| `aggressiveResize` | on              | Behaves better across multiple monitors       |
| `keyMode`          | `vi`            | Vi keys in copy mode                          |
| `mouse`            | on              | Scroll, click panes, drag borders             |
| `terminal`         | `tmux-256color` | Modern terminfo                               |
| `focus-events`     | on              | Passes focus to apps, fixes nvim autoread     |

## Keybindings

Every bind uses the `Ctrl+a` prefix unless noted. Press the prefix, let go, then
press the key.

| Keys               | Action                                      |
| ------------------ | ------------------------------------------- |
| `Ctrl+a` `\`       | Split pane **horizontally** (left/right)    |
| `Ctrl+a` `v`       | Split pane **vertically** (top/bottom)      |
| `Ctrl+a` `h/j/k/l` | Move focus left / down / up / right (Vim)   |
| `Ctrl+a` `←/↓/↑/→` | Move focus by arrow (same as h/j/k/l)       |
| `Ctrl+a` `Ctrl+a`  | Jump to the **last window** (Alt-Tab style) |
| `Ctrl+a` `a`       | Send a literal prefix, for **nested** tmux  |
| `Ctrl+a` `m`       | Open the **tmux-menus** popup               |

The `\` and `v` splits are deliberate: the default `\` split is moved aside so it
does not fight the menu trigger. All the usual tmux pane binds still work on top
of these, including `%` and `"` for splits, `z` to zoom, `x` to kill, `c` for a
new window and `[` for copy mode.

### Nested tmux

When you SSH from a local tmux into a remote one, the outer session swallows the
prefix. Press `Ctrl+a` `a` to send a literal `Ctrl+a` through to the inner
session.

### Windows

A tmux window is like a tab: a full-screen workspace that can hold its own panes.
The custom binds above only cover panes, so window management uses tmux defaults.

| Keys              | Action                     |
| ----------------- | -------------------------- |
| `Ctrl+a` `c`      | Create a new window        |
| `Ctrl+a` `0…9`    | Jump to a window by number |
| `Ctrl+a` `n`      | Next window                |
| `Ctrl+a` `p`      | Previous window            |
| `Ctrl+a` `Ctrl+a` | Toggle the last window     |
| `Ctrl+a` `,`      | Rename the current window  |
| `Ctrl+a` `w`      | List and pick a window     |
| `Ctrl+a` `&`      | Kill the current window    |

Open windows show in the middle of the status bar as `index:name` with flags, so
you can always see which one is current.

### Panes

The custom binds cover splitting and moving between panes. The rest of pane
management uses tmux defaults, plus the mouse, which is enabled in the config.

| Keys                   | Action                                       |
| ---------------------- | -------------------------------------------- |
| `Ctrl+a` `z`           | Zoom the current pane to full screen, toggle |
| `Ctrl+a` `x`           | Kill the current pane                        |
| `Ctrl+a` `{` / `}`     | Swap pane with the previous / next one       |
| `Ctrl+a` `Alt+←/↓/↑/→` | Resize the pane by 5 cells (repeatable)      |
| Mouse drag border      | Resize a pane by dragging                    |
| Mouse click pane       | Focus that pane                              |

A zoomed pane shows a `Z` flag next to its window in the status bar. Press
`Ctrl+a` `z` again to restore the layout.

### Sessions

A session is the top-level container that holds your windows. It keeps running on
the server even after you detach, which is what makes the
[SSH auto-attach](#ssh-auto-attach) below work.

| Command or keys    | Action                                    |
| ------------------ | ----------------------------------------- |
| `Ctrl+a` `d`       | Detach from the session, it keeps running |
| `Ctrl+a` `s`       | Pick a session from an interactive tree   |
| `Ctrl+a` `$`       | Rename the current session                |
| `Ctrl+a` `(` / `)` | Switch to the previous / next session     |
| `tmux ls`          | List sessions (run from a plain shell)    |
| `tmux new -s name` | Start a new named session                 |
| `tmux a -t name`   | Attach to an existing session by name     |

The session name is shown on the left of the status bar.

### Copy mode

Copy mode lets you scroll back and select text with the keyboard. The config sets
`keyMode = "vi"`, so movement uses Vim keys, and `set-clipboard on` sends whatever
you copy out through Kitty to the system clipboard.

| Keys                | Action                                 |
| ------------------- | -------------------------------------- |
| `Ctrl+a` `[`        | Enter copy mode                        |
| `h/j/k/l`, `/`, `?` | Move and search like in Vim            |
| `Space`             | Start a selection                      |
| `Enter`             | Copy the selection and leave copy mode |
| `q`                 | Quit copy mode without copying         |

With the mouse on, you can also just drag to select; releasing copies the text
straight to the clipboard. There are no custom `v` or `y` binds, so the defaults
above are what apply.

## Plugins

| Plugin       | Source                          | Notes                                      |
| ------------ | ------------------------------- | ------------------------------------------ |
| `sensible`   | `pkgs.tmuxPlugins.sensible`     | Sane baseline defaults                     |
| `tmux-menus` | `jaclu/tmux-menus` (pinned rev) | Popup menu on `Ctrl+a` `m`, cache disabled |

`tmux-menus` is not in nixpkgs, so it is built locally with `mkTmuxPlugin`
against a pinned commit. The old config used `rev = "main"`, which moves over
time and breaks reproducibility. It is loaded by hand with `run-shell` in
`extraConfig` because `@menus_use_cache` has to be set to `"no"` before the
plugin starts up. The Nix store path is read-only, so the plugin cannot write
its cache there and would otherwise error.

## Status bar

Stylix supplies the colors, and the config only describes the layout.

| Region     | Content                                                               |
| ---------- | --------------------------------------------------------------------- |
| **Left**   | Session name, plus a reversed `PREFIX` indicator while it is held     |
| **Middle** | Window list `index:name` with flags (`*` current, `-` last, `Z` zoom) |
| **Right**  | Weekday, date and time (`%a %d %b  %H:%M`), refreshed every 5 s       |

Activity monitoring is on, so a window with background output gets flagged and a
`visual-activity` message fires.

## Kitty integration

tmux always runs inside Kitty, and the two are tuned to stay out of each other's
way on colors, clipboard and shortcuts. That setup lives in its own page so both
docs can point at one source of truth: [Kitty + tmux](kitty-tmux.md).

## SSH auto-attach

Logging into a host over SSH drops you straight into a persistent tmux session.
For interactive SSH shells that are not already inside tmux or a VS Code
terminal, [`home/shell/zsh.nix`](../home/shell/zsh.nix) runs:

```sh
exec tmux new-session -A -s main
```

`-A` attaches to `main` if it exists and creates it otherwise, so a dropped SSH
connection leaves your work running and the next login picks it back up.

## Mac notes

| Area           | Detail                                                                                                                           |
| -------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| **Touch ID**   | `security.pam.services.sudo_local.reattach = true` loads `pam_reattach`, so Touch ID for `sudo` also works inside tmux or screen |
| **tmuxinator** | Installed as a system package on the Mac for project session layouts                                                             |

## How to apply

### Linux (`ninja` / `windy`)

```bash
just build      # nh os switch .
```

Reload the config in a running session with
`Ctrl+a` `:source-file ~/.config/tmux/tmux.conf`, or just start a new session.

### Mac

Flakes only see git-tracked files, so commit and push first, then re-apply with
`darwin-rebuild`. See [kitty.md → How to apply](kitty.md#mac) for the full remote
workflow.
