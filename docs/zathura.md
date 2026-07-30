# Zathura PDF Viewer

> **Hosts**: Linux (`ninja`, `windy`)
> **Defined in**: [`home/zathura.nix`](../home/zathura.nix), `programs.zathura`

[Zathura](https://pwmt.org/projects/zathura/) is the minimal, keyboard-driven document viewer on Linux hosts. It replaces GNOME Papers as the default application for PDF (`application/pdf`) and EPUB (`application/epub+zip`) documents across the desktop environment.

Stylix manages the color scheme and fonts automatically via `stylix.targets.zathura`.

---

## Keybindings

Zathura uses modal, Vim-style navigation bindings by default:

| Keys                                 | Action                                     |
| :----------------------------------- | :----------------------------------------- |
| `h`/`j`/`k`/`l` or `←`/`↓`/`↑`/`→`   | Scroll left / down / up / right            |
| `gg`/`G` or `Home`/`End`             | Jump to top / bottom of document           |
| `Ctrl+F`/`Ctrl+B` or `PgDown`/`PgUp` | Scroll page down / page up                 |
| `J` / `K`                            | Go to next / previous page                 |
| `+` / `-` / `=`                      | Zoom in / zoom out / reset zoom            |
| `a` / `s`                            | Adjust page width / fit page to window     |
| `r`                                  | Rotate page clockwise                      |
| `Ctrl+R`                             | Toggle recolor (dark mode / contrast mode) |
| `/`                                  | Search text forward                        |
| `?`                                  | Search text backward                       |
| `n` / `N`                            | Jump to next / previous search result      |
| `o`                                  | Open file prompt                           |
| `f`                                  | Follow link on page (hints mode)           |
| `Tab`                                | Toggle index / table of contents outline   |
| `d`                                  | Toggle dual-page display mode              |
| `q`                                  | Quit Zathura                               |

---

## Configuration & Integration

- **Stylix Theme**: Color palette, background, and foreground colors are generated dynamically by Stylix (`stylix.targets.zathura`).
- **System Clipboard**: `selection-clipboard = "clipboard"` ensures selected text copies directly to the system clipboard via Wayland.
- **Default Application**: Configured in [`home/desktop.nix`](../home/desktop.nix) under `xdg.mimeApps.defaultApplications`.
