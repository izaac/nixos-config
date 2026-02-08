# NixOS Configuration

## Overview

- **OS:** NixOS (Branch: 25.11)
- **DE:** KDE Plasma 6 (Wayland)
- **Shell:** Bash + Starship + FNM (Node) + Rustup
- **Terminal:** Kitty + Tmux
- **Editor:** Neovim (LazyVim)
- **Gaming:** Steam (NVIDIA Optimized), Heroic, Lutris, Bottles

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
