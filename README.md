# NixOS Configuration

## Overview

- **OS:** NixOS (Branch: 25.11)
- **DM:** cosmic-greeter (greetd)
- **DE:** COSMIC (Epoch 1)
- **Theme:** Catppuccin Mocha (Blue Accent)
- **Shell:** Brush (Rust) + Starship + Atuin + Zoxide
- **Terminal:** WezTerm + Zellij
- **Editor:** Helix
- **Security:** dbus-broker, sops-nix + age, YubiKey (U2F)
- **Gaming:** Steam (NVIDIA Optimized), Heroic, Lutris, Bottles, GameMode

## Documentation

- [Disaster Recovery & Disko](docs/disko-rebuild.md)
- [Hardware Configuration](docs/hardware.md)
- [NVIDIA Driver Updates](docs/nvidia-driver-updates.md)
- [Security & Hardening](docs/security.md)
- [Secret Management](docs/secrets.md)
- [Zellij Configuration](docs/zellij.md)
- [Wezterm Configuration](docs/wezterm.md)
- [Helix Editor](docs/helix.md)
- [Terminal Workflows & Configuration](docs/zellij-wezterm-workflow.md)
- [Documentation Index](docs/README.md)

## Structure

- `hosts/`: host-specific system configuration (`ninja`, `windy`)
- `modules/`: reusable NixOS modules behind `mySystem.*` options
- `home/`: Home Manager modules for user-level configuration
- `users/`: per-user profile composition
- `overlays/`: package overrides
- Custom packages live in [nix-packages](https://github.com/izaac/nix-packages) and are consumed as a flake input. Use **`nix-init`** to bootstrap new package definitions for this repository.

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
