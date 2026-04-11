# Terminal Workflow: Wezterm + Zellij

## The Philosophy: Why Both?

While both Wezterm and Zellij can split panes and manage tabs, they serve entirely different operational purposes in this configuration.

1. **Wezterm (The Emulator):** Handles the rendering, GPU acceleration, native OS windowing, and _transient_ tasks.
2. **Zellij (The Multiplexer):** Handles long-running state, session persistence across SSH or terminal restarts, and complex project workspace layouts.

## Golden Rules for Splitting & Tabbing

### When to use Wezterm splits (`Ctrl + Shift + ...`)

- Quick, throwaway side-by-side comparisons (e.g., `tail -f` a log while running a command).
- Viewing local `man` pages or documentation alongside a primary task.
- **Rule of thumb:** If you don't care about losing the split when you close the window, use Wezterm.

### When to use Zellij splits (`Ctrl + a`, then `\` or `v`)

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
  - Tab 2: `npm run dev` server + `git` pane (Split: `Ctrl + a` -> `\`)
- **Zellij Session "Backend":**
  - Tab 1: Neovim
  - Tab 2: Docker compose logs + DB client
- **Wezterm Orchestration:**
  - You open Wezterm. You attach to both sessions using Wezterm Tabs.
  - Wezterm Tab 1 -> Attached to Zellij "Frontend" (`zellij attach frontend`).
  - Wezterm Tab 2 (`Ctrl + Shift + T`) -> Attached to Zellij "Backend" (`zellij attach backend`).
  - You can now switch between entirely different project sessions instantly using `Ctrl + Shift + PageDown`.
  - **New:** Use `Ctrl + Shift + P` (Project Picker) in Wezterm to quickly spawn a new tab in a pre-configured project directory.

### 2. The Remote Admin (Nested Multiplexing)

You need to SSH into a server and manage things, but keep your local dev environment active.

- Open Wezterm.
- Start Zellij locally (`zellij`).
- In a Zellij pane, SSH into a remote host like `windy`.
- On `windy`, start another Zellij session (`zellij`).
- **Conflict Resolution:**
  - To manipulate your _local_ Zellij (e.g., split local pane): `Ctrl + a` -> `\`
  - To manipulate the _remote_ Zellij (e.g., split remote pane): `Ctrl + a` -> `a` -> `\`
    _(The first `a` passes the prefix through to the nested session)._
  - **New:** SSH sessions now trigger a color change in the Wezterm tab bar (Rosewater/Peach) to prevent accidentally running local commands on a remote host.

### 3. "I Need More Space" (Zooming)

You have a complex Zellij layout, but you suddenly need to read a massive log file in one of the tiny panes.

- **Zellij Panes:** Use Zellij's native pane maximization (via Pane mode `Ctrl+p` -> `f`, or by mapping a toggle in your Tmux mode). _(Note: `Ctrl+p` uses Zellij's built-in Pane mode, which remains active alongside the Tmux-mode bindings)._ Wezterm's Zoom (`Ctrl + Shift + F`) will NOT maximize an inner Zellij pane if you only have one Wezterm pane running the entire Zellij session.
- **Wezterm Panes:** If your layout consists of multiple _Wezterm-native_ splits, use Wezterm's Zoom (`Ctrl + Shift + F`). This will maximize the currently focused Wezterm pane to fill the entire window without losing the split layout state. Press it again to return to your complex layout.

---

## Enhanced Shell & AI Features

### Semantic Navigation (OSC 133)
The `brush` shell is integrated with Wezterm via OSC 133 escape sequences. This enables "Semantic Zones" which allow you to:
- **Jump to Prompt:** Press `Shift + UpArrow` or `Shift + DownArrow` to skip large command outputs and jump directly to the next/previous shell prompt.
- **Copy Command Output:** Wezterm can select the entire output of the previous command with a single native action.

### Monko AI Helpers
A set of AI-powered shell helpers are available to assist with debugging and explanation:
- **`monko <query>`:** A lightweight alias to ask the Gemini AI a question. It is tuned to provide explanations in a "caveman" style, simplifying complex technical concepts.
- **`ask-monko`:** A diagnostic tool that automatically captures the previously failed command from history and sends it to the AI for analysis and a suggested fix.
- **Smart Completion:** If a command is not found, the shell will automatically suggest using `monko` for assistance.

## Summary Checklist

- **System/UI Level:** `Ctrl + Shift` keys (Wezterm)
- **Project/State Level:** `Ctrl + a` prefix (Zellij)
- **Persistence:** Always Zellij.
- **Transience:** Always Wezterm.
