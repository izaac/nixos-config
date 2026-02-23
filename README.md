# NixOS Configuration

## Overview

- **OS:** NixOS (Branch: 25.11)
- **DM:** GDM (Wayland)
- **DE:** GNOME 49
- **Theme:** Catppuccin Mocha (Mauve Accent)
- **Shell:** Bash + Starship + FNM (Node) + Rustup
- **Terminal:** Kitty + Tmux
- **Editor:** Neovim (LazyVim)
- **Security:** dbus-broker
- **Gaming:** Steam (NVIDIA Optimized), Heroic, Lutris, Bottles, Conty

## Documentation

- [Hardware Configuration](docs/hardware.md)
- [Security & Hardening](docs/security.md)
- [Secret Management](docs/secrets.md)

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
