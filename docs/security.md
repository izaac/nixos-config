# Security & System Hardening

This document outlines the security measures and system hardening techniques implemented in this NixOS configuration.

## AppArmor

AppArmor is a Linux kernel security module that allows the system administrator to restrict programs' capabilities with per-program profiles.

### Implementation

We use AppArmor in a **Blacklist Mode** for primary web browsers to protect sensitive user data while maintaining full application functionality.

- **File**: `modules/core/performance.nix`
- **Browsers Covered**: Chromium, Firefox
- **Protection**:
  - Denies access (including directory listings) to:
    - `~/.ssh/`
    - `~/.gnupg/`
    - `~/.aws/`
    - `~/.kube/`
  - **Audit Logging**: Any attempt to access these directories is logged for security monitoring.
  - **NixOS Compatibility**: Profiles are dynamically patched using direct Nix store paths (e.g., `${pkgs.chromium}/bin/chromium`) for browser binaries, ensuring the profile stays locked to the correct version.

### Commands

```bash
# Check AppArmor status
sudo aa-status

# View AppArmor logs
sudo journalctl -ke -g apparmor
```

## D-Bus Broker

We have replaced the traditional `dbus-daemon` with `dbus-broker`, the high-performance D-Bus message broker implementation used by Fedora and GNOME.

### Benefits

- **Performance**: Reduced latency in desktop communication and service activation.
- **Reliability**: Better handling of resource limits and message ordering.
- **Standard**: Aligns with modern desktop standards (GNOME/Fedora).

### Configuration

Enabled in `modules/core/performance.nix`:
```nix
services.dbus.implementation = "broker";
```

## Memory & Kernel Hardening

- **ZRAM**: High-priority compressed swap to prevent disk thrashing and improve system responsiveness under memory pressure.
- **Kernel Sysctls**:
  - `vm.swappiness = 180`: Aggressive use of ZRAM.
  - `net.ipv4.tcp_congestion_control = "bbr"`: Improved network performance and latency.
