# Terminal Workflow: Wezterm + Zellij

## The Philosophy: Why Both?
While both Wezterm and Zellij can split panes and manage tabs, they serve entirely different operational purposes in this configuration.

1. **Wezterm (The Emulator):** Handles the rendering, GPU acceleration, native OS windowing, and *transient* tasks.
2. **Zellij (The Multiplexer):** Handles long-running state, session persistence across SSH or terminal restarts, and complex project workspace layouts.

## Golden Rules for Splitting & Tabbing

### When to use Wezterm splits (`Ctrl + Shift + ...`):
- Quick, throwaway side-by-side comparisons (e.g., `tail -f` a log while running a command).
- Viewing local `man` pages or documentation alongside a primary task.
- **Rule of thumb:** If you don't care about losing the split when you close the window, use Wezterm.

### When to use Zellij splits (`Ctrl + a`, then `\|` or `v`):
- Setting up a development environment (e.g., editor on the left, server output on the right, git status below).
- Any workspace that you might want to detach from and return to later.
- Long-running processes that shouldn't die if the UI or SSH connection drops.
- **Rule of thumb:** If the layout represents a "project state", use Zellij.

---

## Example Workflows

### 1. The Multi-Project Developer
You are working on a frontend app and a backend API simultaneously.

- **Zellij Session "Frontend":** 
  - Tab 1: Neovim (`Ctrl+a` -> `c`)
  - Tab 2: `npm run dev` server + `git` pane (Split: `Ctrl + a` -> `\|`)
- **Zellij Session "Backend":**
  - Tab 1: Neovim
  - Tab 2: Docker compose logs + DB client
- **Wezterm Orchestration:**
  - You open Wezterm. You attach to both sessions using Wezterm Tabs.
  - Wezterm Tab 1 -> Attached to Zellij "Frontend" (`zellij attach frontend`).
  - Wezterm Tab 2 (`Ctrl + Shift + T`) -> Attached to Zellij "Backend" (`zellij attach backend`).
  - You can now switch between entirely different project sessions instantly using `Ctrl + Shift + PageDown`.

### 2. The Remote Admin (Nested Multiplexing)
You need to SSH into a server and manage things, but keep your local dev environment active.

- Open Wezterm.
- Start Zellij locally (`zellij`).
- In a Zellij pane, SSH into a remote host like `windy`.
- On `windy`, start another Zellij session (`zellij`).
- **Conflict Resolution:** 
  - To manipulate your *local* Zellij (e.g., split local pane): `Ctrl + a` -> `\|`
  - To manipulate the *remote* Zellij (e.g., split remote pane): `Ctrl + a` -> `a` -> `\|` 
    *(The first `a` passes the prefix through to the nested session).*

### 3. "I Need More Space" (Zooming)
You have a complex Zellij layout, but you suddenly need to read a massive log file in one of the tiny panes.

- **Zellij Panes:** Use Zellij's native pane maximization (via Pane mode `Ctrl+p` -> `f`, or by mapping a toggle in your Tmux mode). *(Note: `Ctrl+p` uses Zellij's built-in Pane mode, which remains active alongside the Tmux-mode bindings).* Wezterm's Zoom (`Ctrl + Shift + F`) will NOT maximize an inner Zellij pane if you only have one Wezterm pane running the entire Zellij session.
- **Wezterm Panes:** If your layout consists of multiple *Wezterm-native* splits, use Wezterm's Zoom (`Ctrl + Shift + F`). This will maximize the currently focused Wezterm pane to fill the entire window without losing the split layout state. Press it again to return to your complex layout.

## Summary Checklist
- **System/UI Level:** `Ctrl + Shift` keys (Wezterm)
- **Project/State Level:** `Ctrl + a` prefix (Zellij)
- **Persistence:** Always Zellij.
- **Transience:** Always Wezterm.
