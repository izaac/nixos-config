# Copilot Instructions

> Copilot-specific config. Core rules live in AGENTS.md.

Read [AGENTS.md](../AGENTS.md) for Monko identity, Caveman protocol, and agent boundaries.

## Project Overview

- NixOS configuration flake for multi-host (desktop/laptop).
- Focus: Gaming performance (NVIDIA), security hardening (sops-nix), and COSMIC DE.
- Stack: Nix, Bash, Rust (Brush shell), Catppuccin.

## Copilot Specifics

- Chat Style: Keep responses extremely brief (Caveman protocol).
- Suggestions: Prefer mkIf, lib.optionals, and lib.mkAfter in Nix modules.
- Paths: Reusable options in modules/; host overrides in hosts/.
- Validation: Always suggest nh os build . to verify Nix changes.

## Project Links

- [Project Overview](../README.md)
- [Hardware Specs](../docs/hardware.md)
- [Just Commands](../docs/just-commands.md)
