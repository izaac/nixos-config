# NixOS Configuration

Personal NixOS flake managing two hosts (`ninja`, `windy`). Tracks **nixos-unstable**.
Custom packages live in a separate [nix-packages](https://github.com/izaac/nix-packages) repo consumed as a flake input.

## Overview

- **OS:** NixOS (Branch: 25.11)
- **DM:** tuigreet (greetd) with YubiKey U2F
- **Compositor:** [Niri](https://github.com/YaLTeR/niri) (scrollable-tiling Wayland) via [niri-flake](https://github.com/sodiboo/niri-flake) — unstable channel for xwayland-satellite
- **Shell of the desktop:** Waybar (bar) + fuzzel (launcher) + mako (notifications) + swaylock-effects/swayidle (lock) + wlogout (power menu)
- **File manager:** Nemo (+ file-roller, ffmpegthumbnailer)
- **Theme:** Catppuccin Mocha Blue, system-wide via [Stylix](https://github.com/danth/stylix)
- **Shell:** Bash + Ble.sh + Starship + Atuin + Zoxide
- **Terminal:** Ghostty + tmux
- **Editor:** LazyVim (Neovim distribution)
- **Security:** dbus-broker, sops-nix + age, YubiKey (U2F)
- **Gaming:** Steam (NVIDIA Optimized), Lutris, Bottles, GameMode, sched-ext
- **Kernel (ninja):** Linux 7.0.10 pinned + slim config (see [docs/kernel-slim.md](docs/kernel-slim.md))

## Structure

```text
flake.nix          # Entry point — defines inputs, hosts, devShells, checks
lib/               # mkSystem helper, user config
hosts/             # Per-host configuration.nix + hardware
modules/           # Reusable NixOS modules (mySystem.* options)
  core/            # Audio, codecs, nix-ld, performance, sops, maintenance
  desktop/         # Niri compositor, tuigreet greeter, NVIDIA glue
  gaming/          # Steam, GameMode, sched-ext (SCX)
home/              # Home Manager modules (per-app .nix files)
  niri.nix         # Compositor config, keybinds, spawn-at-startup
  waybar.nix       # Status bar
  launcher.nix     # fuzzel launcher
  notifications.nix # mako
  screenlock.nix   # swaylock + swayidle
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
- [Slim Kernel (ninja)](docs/kernel-slim.md)
- [Security & Hardening](docs/security.md) | [Secrets](docs/secrets.md)
- [Disaster Recovery & Disko](docs/disko-rebuild.md)
- [CLI Tools](docs/cli-tools.md) | [Just Commands](docs/just-commands.md)
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
