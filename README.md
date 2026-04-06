# NixOS Configuration

## Overview

- **OS:** NixOS (Branch: 25.11)
- **DM:** GDM (Wayland)
- **DE:** GNOME 49
- **Theme:** Catppuccin Mocha (Mauve Accent)
- **Shell:** Zsh + Starship + Atuin + Rust Coreutils
- **Terminal:** Kitty + Tmux
- **Editor:** Neovim (LazyVim)
- **Security:** dbus-broker
- **Gaming:** Steam (NVIDIA Optimized), Heroic, Lutris, Bottles, Conty

## Documentation

- [Hardware Configuration](docs/hardware.md)
- [NVIDIA Driver Updates](docs/nvidia-driver-updates.md)
- [Security & Hardening](docs/security.md)
- [Secret Management](docs/secrets.md)
- [Documentation Index](docs/README.md)

## Structure

- `hosts/`: host-specific system configuration (`ninja`, `windy`)
- `modules/`: reusable NixOS modules behind `mySystem.*` options
- `home/`: Home Manager modules for user-level configuration
- `users/`: per-user profile composition
- `pkgs/` and `overlays/`: custom packages and package overrides

## Quick Start

To apply changes and switch to the new configuration:

```bash
# Using nh (recommended)
nh os switch .

# Standard Nix
sudo nixos-rebuild switch --flake .

# Update all flake inputs
nix flake update

# Clean old generations
nh clean all
```
