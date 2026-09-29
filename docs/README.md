# Documentation Index

## Project

- [Adding a New Host](adding-a-host.md)
- [Hardware Configuration (ninja)](hardware.md)
- [Host Notes (windy)](windy.md)
- [Hardware Configuration (plex)](plex.md)
- [Host Configuration (Mac)](mac.md)
- [NVIDIA Driver Updates](nvidia-driver-updates.md)
- [nixpkgs-unstable Usage Reference](nixpkgs-unstable.md)
- [Security & Hardening](security.md)
- [Secret Management](secrets.md)
- [GitHub SSH Host Key Pinning](known-hosts.md)
- [System Recovery with Disko (ninja)](disko-rebuild.md)

## Architecture & Profiles

The system uses modular host role profiles (`modules/profiles/`):

- **Workstation** (`modules/profiles/workstation.nix`): Full desktop stack, dev tooling, audio,
  gaming, and sops secrets (`ninja`, `windy`).
- **Server** (`modules/profiles/server.nix`): Minimal headless server footprint, tailscale subnet
  router, no GUI packages (`plex`).
- **Laptop** (`modules/profiles/laptop.nix`): Shared power management, TLP, thermald, battery
  thresholds, and backlight controls (`windy`).

Adding a new host requires only a `hosts/<name>/` directory with a `system.nix` file. See
[Adding a New Host](adding-a-host.md) for the full guide.

## Tools & Workflows

- [Just Command Guide](just-commands.md)
- [CLI Tools and Comma Integration](cli-tools.md)
- [Linux Builder (Mac)](linux-builder.md)
- [Niri Compositor](niri.md)
- [ashell Desktop Shell](ashell.md)
- [Kitty Terminal](kitty.md)
- [tmux (terminal multiplexer)](tmux.md)
- [Kitty + tmux integration](kitty-tmux.md)
- [LazyVim (Neovim)](lazyvim.md)
- [mpv Media Player](mpv.md)
- [Zathura PDF Viewer](zathura.md)

## Agent Instructions

- [Token Optimization Playbook](agent-token-shield.md)
- [Agent Troubleshooting](agent-troubleshooting.md)
