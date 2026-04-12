# CLI Tools and Command Integration

This repository integrates several modern, Rust-based CLI utilities designed to improve performance and safety compared to traditional GNU coreutils.

## The Comma Utility (`,`)

The `comma` tool (a wrapper for `nix-index`) allows for the execution of software without requiring a permanent installation in the user environment. This is ideal for one-off tasks or testing new packages.

### Usage
Prepend any command with a comma to execute it via Nix:
```bash
, cowsay "Hello from Nix"
```

**Mechanism:** `comma` queries the Nix package index to identify the correct package for the requested binary, downloads it to the Nix store temporarily, executes the command, and ensures the environment remains uncluttered.

## Core Utility Replacements

The following tools are integrated and aliased by default:

- **`rip` (rm-improved):** A safe replacement for `rm`. Instead of immediate deletion, files are moved to a temporary "shredder" directory from which they can be recovered.
- **`bat`:** A replacement for `cat` that provides syntax highlighting and Git integration.
- **`eza`:** A feature-rich replacement for `ls` with support for icons, color formatting, and integrated Git status.
- **`zoxide` (`z`):** A smart directory jumper that learns your most-used paths to enable rapid navigation.
- **`btop`:** A graphical system monitor for real-time tracking of CPU, memory, and network usage.
- **`yazi` (`y`):** A terminal-based file manager with high-performance image previews and intuitive navigation.
