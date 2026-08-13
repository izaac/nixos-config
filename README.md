# NixOS Configuration

Personal flake managing two NixOS hosts (`ninja`, `windy`) and a nix-darwin Mac.
Tracks **nixos-26.05 stable**. Custom packages live in a separate
[nix-packages](https://github.com/izaac/nix-packages) repo consumed as a flake input.

## Overview

- **OS:** NixOS 26.05 (stable) + nix-darwin 26.05 (Mac)
- **DM:** [ReGreet](https://github.com/rharish101/ReGreet) (greetd, in cage) with YubiKey U2F
- **Compositor:** [Niri](https://github.com/YaLTeR/niri) (scrollable-tiling Wayland) via [niri-flake](https://github.com/sodiboo/niri-flake)
- **Shell of the desktop:** [ashell](https://github.com/MalpenZibo/ashell) on every Linux host (bar, control center, notifications, OSD; Rust + iced), with fuzzel, swaylock, swayidle, [stash](https://github.com/NotAShelf/stash) and wlogout filling the gaps.
- **File manager:** Nemo (+ file-roller, ffmpegthumbnailer)
- **Theme:** App colors are Catppuccin Mocha Blue, system-wide via [Stylix](https://github.com/danth/stylix); the desktop shell palette is generated from the current wallpaper by [matugen](https://github.com/InioX/matugen)
- **Wallpaper:** [awww](https://codeberg.org/LGFae/awww) daemon, driven by the `set-wallpaper` helper
- **Shell:** Zsh + Starship + Atuin + Zoxide (all hosts, Mac included)
- **Terminal:** Kitty + tmux
- **Editor:** LazyVim (Neovim distribution)
- **Security:** dbus-broker, sops-nix + age, YubiKey (U2F), pinned binary caches
- **Gaming:** Steam (NVIDIA Optimized), Lutris, Bottles, GameMode, sched-ext
- **Kernel (ninja):** nixpkgs `linux_latest` built with `-march=native` (X86_NATIVE_CPU) + 1000Hz, see `hosts/ninja/kernel.nix`

## Structure

```text
flake.nix          # Entry point: defines inputs, hosts, devShells, checks
lib/               # mkSystem helper, user config
hosts/             # Per-host configuration.nix + hardware
modules/           # Reusable NixOS modules (mySystem.* options)
  core/            # Audio, codecs, nix-ld, performance, sops, maintenance
  desktop/         # Niri compositor, ReGreet greeter, NVIDIA glue
  gaming/          # Steam, GameMode, sched-ext (SCX)
home/              # Home Manager modules (per-app .nix files)
  niri.nix         # Compositor config, shell-agnostic keybinds
  ashell.nix       # ashell shell + matugen theming + wallpaper
  lock.nix         # swaylock, swayidle, wlogout
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
- [CLI Tools](docs/cli-tools.md) | [Just Commands](docs/just-commands.md)
- [Niri Keybindings & UX](docs/niri.md) | [ashell Shell](docs/ashell.md)
- [LazyVim (Neovim)](docs/lazyvim.md)
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
