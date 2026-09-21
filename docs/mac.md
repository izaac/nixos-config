# Host Configuration - Mac

> **System**: Apple Silicon Mac (macOS / `aarch64-darwin`)  
> **Defined in**: [`hosts/Mac/configuration.nix`](../hosts/Mac/configuration.nix),
> [`lib/mkDarwin.nix`](../lib/mkDarwin.nix)

---

## Overview

The `Mac` host manages the macOS environment declaratively using **nix-darwin** combined with **Home
Manager** and native **Homebrew** cask management.

| Component             | Technology                             | Notes                                                |
| :-------------------- | :------------------------------------- | :--------------------------------------------------- |
| **OS / Architecture** | macOS / `aarch64-darwin`               | Apple Silicon                                        |
| **System Manager**    | nix-darwin (`inputs.darwin`)           | Configured via `lib/mkDarwin.nix`                    |
| **User Environment**  | Home Manager (`inputs.home-manager`)   | Loads `home/core.nix`, `lazyvim.nix`, `zed.nix`      |
| **GUI Applications**  | Homebrew Casks                         | Managed declaratively via `homebrew.casks`           |
| **Linux Offload**     | Linux Builder VM (`nix.linux-builder`) | Headless NixOS VM for cross-compiling Linux packages |

---

## Build & Switch Workflow

Rebuilding the macOS environment uses `just`:

```bash
just build          # Automatically runs `just darwin-build` on macOS
just darwin-build   # Ensures builder runs, then executes sudo -H darwin-rebuild switch --flake .#Mac
```

The build recipe runs an idempotent check (`just ensure-builder`) to make sure the Linux builder VM
is available before building derivations.

---

## Linux Builder VM

Because macOS cannot natively build `x86_64-linux` or `aarch64-linux` Nix store paths, the Mac runs
an on-demand local NixOS virtual machine via the Apple Virtualization framework.

- Documentation: [Linux Builder (Mac)](linux-builder.md)
- Control commands:
  - `just builder-start` — starts the VM when Linux builds are needed.
  - `just builder-stop` — stops the VM to free ~1GB RAM and CPU.
  - `just builder-status` — checks if the VM daemon is currently loaded and running.
  - `just builder-reset` — recreates the persistent VM disk (`nixos.qcow2`).

---

## Power Management & Sleep

Power management is configured via `pmset` in post-activation scripts:

- **Battery**: System sleep after 15 minutes, Power Nap disabled to preserve charge
  (`pmset -b sleep 15 powernap 0`).
- **AC Power**: System sleep after 30 minutes (`pmset -c sleep 30`).
- **Display Sleep**: 10 minutes on both power sources.

### On-Demand Sleep Prevention

To keep the machine awake temporarily from the CLI:

```bash
caffeinate -d -i         # Prevent display and idle sleep (stop with Ctrl+C)
caffeinate -d -i -t 3600 # Stay awake for 1 hour
```

To permanently disable sleep on battery:

```bash
sudo pmset -b sleep 0    # Undo with: sudo pmset -b sleep 15
```

---

## Podman Machine & krunkit Overlay

`podman machine` on macOS uses the `libkrun` provider, which shells out to `krunkit` on `$PATH`.
Because Homebrew's `podman` formula does not ship `krunkit`:

1. `krunkit` is provided from `nixpkgs-unstable` via overlay
   [`overlays/krunkit-unstable.nix`](../overlays/krunkit-unstable.nix).
2. EFI firmware paths are linked into the system profile with
   `environment.pathsToLink = ["/share/krunkit"]`.
3. Homebrew installs the `podman` CLI tool (`homebrew.brews = ["podman"]`).

---

## Homebrew Integration

`nix-darwin` coordinates installed applications via Homebrew. Homebrew must be installed once
initially; thereafter, `homebrew.onActivation` handles updates and upgrades.

- **Cleanup policy**: `cleanup = "none"`, ensuring manually installed tools or casks outside the
  config are not purged.
- **Key GUI Casks**:
  - Editors: `zed`
  - Terminals: `ghostty`, `iterm2`
  - Collaboration: `slack`
  - Browsers: `firefox`, `google-chrome`, `microsoft-edge`
  - Media & Remote: `moonlight`, `plexamp`, `tailscale-app`, `windows-app`

---

## System Defaults & Security

Configured in `system.defaults`:

- **Touch ID for Sudo**: Enabled via `security.pam.services.sudo_local.touchIdAuth = true`, with
  `pam_reattach` so Touch ID works inside tmux.
- **Dock**: Instant auto-hide (`autohide-delay = 0.0`), no bouncing launch animation, minimized
  windows into application icon.
- **Trackpad**: Tap to click enabled (`Clicking = true`).
- **Application Firewall**: Enabled with signed applications allowed and stealth mode off
  (`networking.applicationFirewall`).
- **Screenshots**: Saved to `~/Screenshots` in PNG format with window drop-shadows disabled.
