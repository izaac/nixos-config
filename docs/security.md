# Security & System Hardening

This document outlines the security measures and system hardening techniques implemented in this NixOS configuration.

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
