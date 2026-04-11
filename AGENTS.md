# AGENTS.md — NixOS Configuration

> Instruction file for AI coding agents (Copilot, Claude, Gemini).
> Symlinked to `GEMINI.md`, `CLAUDE.md`, and `.github/copilot-instructions.md`.

## Project Overview

Personal NixOS flake managing two hosts (`ninja`, `windy`). Tracks **nixos-unstable**.
Custom packages live in a separate [nix-packages](https://github.com/izaac/nix-packages) repo consumed as a flake input.

## Hosts

| Host      | Role                | GPU                  | Desktop   |
| --------- | ------------------- | -------------------- | --------- |
| **ninja** | Primary workstation | NVIDIA (Beta driver) | COSMIC DE |
| **windy** | Secondary / laptop  | Integrated           | COSMIC DE |

## Repository Structure

```text
flake.nix          # Entry point — defines inputs, hosts, devShells, checks
lib/               # mkSystem helper, user config
hosts/             # Per-host configuration.nix + hardware
modules/           # Reusable NixOS modules (mySystem.* options)
  core/            # Audio, codecs, nix-ld, performance, sops, maintenance
  desktop/         # COSMIC DE, display manager
  gaming/          # Steam, GameMode, sched-ext (SCX)
home/              # Home Manager modules (per-app .nix files)
users/             # Per-user profile composition
overlays/          # Package overrides (e.g., dwarfs boost pin)
crunch/            # Media encoding configs
secrets.yaml       # SOPS-encrypted secrets
docs/              # Human-readable documentation
```

## Tech Stack

- **Shell**: Brush (Rust bash-compatible) + Starship + Atuin + Zoxide
- **Terminal**: WezTerm + Zellij
- **Editor**: Helix
- **Theme**: Catppuccin Mocha (system-wide via catppuccin/nix)
- **Security**: sops-nix + age, dbus-broker, YubiKey
- **Gaming**: Steam, Heroic, Lutris, Bottles, GameMode, sched-ext

## Agent Boundaries

### ✅ Always

- Use `nix run nixpkgs#<tool>` or `nix shell nixpkgs#<tool>` to run tools not in the dev shell
- Write idiomatic Nix — use `mkOption`, `mkDefault`, `mkIf`, `lib.optionals`
- Format with `alejandra` (enforced by pre-commit hooks; `nixpkgs-fmt` is used in `nix flake check`)
- Test changes with `nix flake check` before committing
- Use the existing module pattern: options under `mySystem.*`, config in `modules/`
- Home Manager config goes in `home/*.nix`, system config in `modules/`
- Keep host-specific overrides in `hosts/<hostname>/configuration.nix`

### ⚠️ Ask First

- Adding new flake inputs
- Changing kernel or NVIDIA driver versions
- Modifying `secrets.yaml` or sops configuration
- Changing the login shell or display manager

### 🚫 Never

- Commit secrets, keys, or tokens
- Modify `flake.lock` manually (use `nix flake update` or `nix flake lock --update-input`)
- Edit files in `result/` or `/nix/store/`
- Perform any actions regarding `markdown.sh`

## Tools & Commands

```bash
# Rebuild and switch (preferred)
nh os switch .             # or use the 'nrb' shell function

# Dry-run rebuild
nh os switch . -- --dry-run

# Update flake inputs
nix flake update

# Format (alejandra via pre-commit, nixpkgs-fmt via flake check)
nix flake check

# Lint Nix (also run automatically by pre-commit hooks)
statix check .
deadnix .

# Lint & format Markdown (config: .markdownlint.yaml)
# Always run prettier first, then markdownlint for remaining issues
nix run nixpkgs#prettier -- --write '**/*.md'
nix run nixpkgs#markdownlint-cli2 -- '**/*.md'

# Dev shell (includes nixd, statix, deadnix, nixpkgs-fmt, sops tools)
nix develop
```

## Conventions

- **Caveman talk** when explaining things or chatting with the user; normal modern prose for documentation and code comments
- **No conventional commit prefixes** (no `feat:`, `fix:`, etc.)
- **No co-author trailers** on commits
- Modules use `with lib;` and `{ config, lib, pkgs, ... }:` pattern
- Aliases that chain commands (`&&`) must be **functions**, not aliases (brush limitation)
- Custom packages belong in `nix-packages` repo, not here
- Prefer Rust-based CLI tools where viable alternatives exist

## Key Technical Details

- **Brush shell** reads `~/.brushrc` after `~/.bashrc` — use it for post-init fixes
- **Brush config** lives at `~/.config/brush/config.toml` — `zsh-hooks = true` enables atuin
- **NVIDIA driver** tracks the Beta branch — kernel must be compatible
- **Sched-ext**: `extraArgs` must be overridden per-host (not all schedulers accept `--autopilot`)
- **Firefox policies** are enforced at system level in `hosts/ninja/configuration.nix`
- **nix-ld** is configured with an extensive library list for AppImage compatibility
