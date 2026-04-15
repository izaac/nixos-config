# NixOS Configuration

Personal NixOS flake managing two hosts (`ninja`, `windy`). Tracks **nixos-unstable**.
Custom packages live in a separate [nix-packages](https://github.com/izaac/nix-packages) repo consumed as a flake input.

## Overview

- **OS:** NixOS (Branch: 25.11)
- **DM:** cosmic-greeter (greetd)
- **DE:** COSMIC (Epoch 1)
- **Theme:** Catppuccin Mocha (Blue Accent, system-wide via catppuccin/nix)
- **Shell:** Brush (Rust bash-compatible) + Starship + Atuin + Zoxide
- **Terminal:** WezTerm + Zellij
- **Editor:** Helix
- **Security:** dbus-broker, sops-nix + age, YubiKey (U2F)
- **Gaming:** Steam (NVIDIA Optimized), Heroic, Lutris, Bottles, GameMode, sched-ext

## Structure

```text
flake.nix          # Entry point — defines inputs, hosts, devShells, checks
lib/               # mkSystem helper, user config
hosts/             # Per-host configuration.nix + hardware
modules/           # Reusable NixOS modules (mySystem.* options)
  core/            # Audio, codecs, nix-ld, performance, sops, maintenance
  desktop/         # COSMIC DE, display manager
  gaming/          # Steam, GameMode, sched-ext (SCX)
home/              # Home Manager modules (per-app .nix files)
  shell/           # Split shell config (aliases, functions, packages)
users/             # Per-user profile composition
overlays/          # Package overrides
secrets.yaml       # SOPS-encrypted secrets
docs/              # Human-readable documentation
```

Custom packages live in [nix-packages](https://github.com/izaac/nix-packages) and are consumed as a flake input. Use **`nix-init`** to bootstrap new package definitions.

## Documentation

- [Hardware (ninja)](docs/hardware.md) | [Hardware (windy)](docs/windy.md)
- [NVIDIA Driver Updates](docs/nvidia-driver-updates.md)
- [Security & Hardening](docs/security.md) | [Secrets](docs/secrets.md)
- [Disaster Recovery & Disko](docs/disko-rebuild.md)
- [Zellij](docs/zellij.md) | [Wezterm](docs/wezterm.md) | [Workflow](docs/zellij-wezterm-workflow.md)
- [Helix Editor](docs/helix.md) | [CLI Tools](docs/cli-tools.md) | [Just Commands](docs/just-commands.md)
- [Full Index](docs/README.md)

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
