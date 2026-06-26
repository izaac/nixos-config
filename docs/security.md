# Security & System Hardening

This document outlines the security measures and system hardening techniques implemented in this NixOS configuration.

## Disk Encryption (LUKS)

Both hosts use encrypted root volumes via initrd-unlocked LUKS devices:

- `hosts/ninja/hardware.nix`:
  - `boot.initrd.luks.devices."luks-782b8c84-..."`
- `hosts/windy/hardware.nix`:
  - `boot.initrd.luks.devices."luks-16413ece-..."`

This protects data at rest for system partitions.

## Secrets Management (sops-nix + age)

Secrets are encrypted in-repo (`secrets/common.yaml`) and decrypted at activation/runtime by `sops-nix`.

- Module: `modules/core/sops.nix`
- Key location is derived from the configured user home:
  - `age.keyFile = "${config.users.users.${userConfig.username}.home}/.config/sops/age/keys.txt"`
- Current managed secrets:
  - `sshHost`
  - `geminiProject`
  - `cloudCodeProject`

## SSH and Privilege Defaults

`modules/core/system.nix` disables sshd by default (`services.openssh.enable = lib.mkDefault false`); each host opts in and hardens it in its own `ssh.nix`:

- `hosts/ninja/ssh.nix` / `hosts/windy/ssh.nix`:
  - `services.openssh.enable = true`
  - `PasswordAuthentication = false`
  - `KbdInteractiveAuthentication = false`
  - `PermitRootLogin = "no"`

Privilege escalation uses the memory-safe Rust `sudo-rs` (C `sudo` is `mkForce`-disabled in `modules/core/system.nix`):

- `modules/core/system.nix`: `security.sudo-rs.enable = lib.mkForce true`
- `modules/core/user.nix`: `security.sudo-rs.wheelNeedsPassword = true`

## Firewall and Network Exposure

Host firewall policy on ninja is enabled in `hosts/ninja/network.nix` (windy enables `networking.firewall.enable = true` in its own `network.nix`):

- `networking.firewall.enable = true`
- Explicit TCP port `22` (SSH)
- KDE Connect range `1714-1764` (TCP/UDP)
- Declarative nftables input exception for NAS host:
  - `extraInputRules = '' ip saddr 192.168.0.173 accept ''`

## D-Bus Broker

Desktop message bus uses `dbus-broker` (`modules/core/performance.nix`):

```nix
services.dbus.implementation = "broker";
```

Benefits:

- Lower desktop IPC latency
- Better resource handling
- Aligns with modern GNOME/Fedora defaults

## Memory and Kernel Runtime Defaults

Performance-sensitive defaults with security relevance:

- ZRAM enabled with `zstd` (high-priority compressed swap)
- `vm.swappiness = 180` (optimized for zram-backed swap on fast NVMe systems)
- `net.ipv4.tcp_congestion_control = "bbr"`

These are tuned for responsiveness and may be adjusted per-host if threat model or workload changes.

## Operational Guidance

- Rotate/reencrypt secrets when adding/removing machines: `sops updatekeys secrets/common.yaml`
- Keep SSH keys and age identities outside the repository
- Review open firewall ports whenever enabling new services
- Reassess performance-oriented kernel/network tuning after major NixOS upgrades
