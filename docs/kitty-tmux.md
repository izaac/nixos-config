# Kitty + tmux

> How the terminal and the multiplexer fit together.
> See also: [Kitty Terminal](kitty.md) and [tmux](tmux.md).

On every host tmux runs inside Kitty. They stack in two layers, and most of the
friction people hit with terminal multiplexers (washed-out colors, broken
clipboard, clashing shortcuts) is already handled by the settings below.

## Who owns what

Think of it as two layers. Kitty is the window you see on screen, and tmux lives
one level down inside it.

| Job                | Handled by | How                                                 |
| ------------------ | ---------- | --------------------------------------------------- |
| Sessions and panes | tmux       | Splits, windows and panes all go through the prefix |
| Tabs and windows   | kitty      | Kitty's own tabs and OS windows sit above tmux      |

In practice tmux does the day-to-day pane work and Kitty's splits stay unused.
Both sets of splits exist, they just never get in each other's way.

## Why the shortcuts never clash

Every Kitty bind starts with `Ctrl+Shift`, `Ctrl+Tab` or `Shift+Arrow`. Every
tmux bind goes through the `Ctrl+a` prefix first. Because the two never share an
opening key, a keypress is always unambiguous: if you held the prefix it is
tmux, otherwise it is Kitty.

So both of these can live side by side without confusion:

- Kitty split: `Ctrl+Shift+N` (horizontal), `Ctrl+Shift+\` (vertical)
- tmux split: `Ctrl+a \` (horizontal), `Ctrl+a v` (vertical)

Full lists live in [kitty.md](kitty.md#keybindings) and
[tmux.md](tmux.md#keybindings).

## Colors, clipboard and focus

A few tmux settings exist purely to let Kitty's modern features through instead
of getting in their way.

| What you get | Setting in `home/tmux.nix`                                          | Why it matters                                                                                       |
| ------------ | ------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| True color   | `terminal-overrides ",*-256color:Tc"`, `terminal-features ",*:RGB"` | Tells tmux that Kitty can do full RGB, so themes render at full fidelity                             |
| Clipboard    | `set-clipboard on`                                                  | tmux yanks ride Kitty's OSC 52 relay straight to the Wayland or macOS clipboard                      |
| Focus events | `focus-events on`                                                   | Passes window focus in and out, so apps inside tmux (like nvim autoread) notice when you switch away |

Without the color settings tmux would fall back to 256 colors and the Catppuccin
theme would look muddy. Without `set-clipboard on` a yank inside tmux would never
leave the pane. Both are easy to forget and annoying to debug, which is why they
are spelled out here.
