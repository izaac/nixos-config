# zsh

> **Hosts**: all (`ninja` on Linux, `Mac` on Apple Silicon) **Defined in**:
> [`home/shell/zsh.nix`](../home/shell/zsh.nix), `programs.zsh`, with `dotDir` pointing at
> `$XDG_CONFIG_HOME/zsh`

zsh is the interactive and login shell. `dotDir` moves the startup files out of `$HOME`, so the rc
lives at `~/.config/zsh/.zshrc` and `.zshenv` there exports `ZDOTDIR`. Anything that sources a shell
config by path needs that path, not `~/.zshrc`.

## Which keymap you get

zsh defaults to the `emacs` keymap, but on this system the keymap follows `VISUAL`. Any value
containing `vi`, including `nvim`, `vim`, `gvim` and `nvi`, selects the `viins` keymap. Values such
as `nano` or `code` leave it on `emacs`. This mapping is not set anywhere in this repo, so it should
be treated as observed behaviour rather than intended policy.

```console
$ env -i VISUAL=nvim zsh -f -c 'bindkey -lL main'
bindkey -A viins main
$ env -i VISUAL=nano zsh -f -c 'bindkey -lL main'
bindkey -A emacs main
```

Check the live shell with `bindkey -lL main`. A host that does not export `VISUAL` lands in `emacs`,
which is why a plain Slackware box and `ninja` behave differently with the same shell.

## Keybindings

### vi mode (`bindkey -A viins main`)

Press `Esc` to leave insert mode, then the usual vim motions.

| Key       | Action                   |
| --------- | ------------------------ |
| `b` / `w` | word back / forward      |
| `h` / `l` | character back / forward |
| `0` / `$` | line start / end         |
| `e`       | end of word              |
| `i` / `a` | back to insert mode      |
| `dd`      | kill line                |
| `dw`      | delete word              |
| `x`       | delete character         |
| `u`       | undo                     |
| `/text`   | history search           |

### emacs mode (`bindkey -A emacs main`)

| Key                 | Action                   |
| ------------------- | ------------------------ |
| `Alt+B` / `Alt+F`   | word back / forward      |
| `Ctrl+B` / `Ctrl+F` | character back / forward |
| `Ctrl+A` / `Ctrl+E` | line start / end         |
| `Ctrl+W`            | delete word backward     |
| `Ctrl+U` / `Ctrl+K` | kill to line start / end |
| `Ctrl+R`            | history search           |

## Ctrl+Left and Ctrl+Right

These print literal text such as `;5D` on a stock setup. `xterm-256color` terminfo defines no
`kLFT5` / `kRIT5` capability, so zsh never binds the sequences, consumes the `ESC[1` prefix and
leaves the remainder on screen:

```console
$ infocmp -1 xterm-256color | grep -E 'kLFT5|kRIT5'
$ bindkey '^[[1;5D'
"^[[1;5D" undefined-key
```

`home/shell/zsh.nix` binds them explicitly in `initContent`, together with Alt+arrows, in both
`emacs` and `viins`:

```zsh
bindkey -M emacs "^[[1;5D" backward-word
bindkey -M emacs "^[[1;5C" forward-word
bindkey -M viins "^[[1;5D" backward-word
bindkey -M viins "^[[1;5C" forward-word
```

Binding to `main` would be enough in practice, but `main` follows `VISUAL` here, so naming the
keymaps keeps the fix working whichever mode the shell starts in. `vicmd` is left alone: normal mode
already has `b` / `w` and `h` / `l`, and the escape sequences above cannot collide with them.

## Switching keymaps

The `VISUAL` behaviour is incidental, so state the intent explicitly in `initContent` if it matters:

```zsh
bindkey -e    # force emacs keys regardless of VISUAL
bindkey -v    # force vi keys regardless of VISUAL
```

An explicit `bindkey -e` or `bindkey -v` wins over the side effect and makes the shell predictable
across hosts.

## Notes

- tmux receives keys first. Inside a session, keybindings only apply after tmux's own prefix
  (`Ctrl+b`) or when tmux passes the key through.
- `Ctrl+Left` and `Ctrl+Right` also depend on the terminal emulator sending `CSI 1;5C` / `CSI 1;5D`.
  Kitty and most other terminals do; some send nothing at all.
