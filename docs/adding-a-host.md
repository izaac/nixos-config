# Adding a New Host

This repo uses **auto-discovery** to find NixOS and Darwin hosts. Any directory under `hosts/` that
contains a `system.nix` file is automatically detected and added to the flake outputs. No
`flake.nix` edits are needed.

## Quick Start

```bash
# 1. Create the host directory
mkdir hosts/myhost

# 2. Add system.nix (required)
echo '"x86_64-linux"' > hosts/myhost/system.nix

# 3. Create configuration.nix
cat > hosts/myhost/configuration.nix << 'EOF'
{ ... }: {
  imports = [
    ../common.nix
    ../../modules/profiles/workstation.nix
  ];
}
EOF

# 4. Build and switch
nh os switch .#myhost
```

That is it. The host is automatically added to `nixosConfigurations`, `nix flake check`, and all
flake outputs.

## How It Works

The flake reads all directories under `hosts/` using `builtins.readDir`. For each directory, it
imports `system.nix` to determine the system type. Hosts are then split into `nixosConfigurations`
and `darwinConfigurations` based on the system type.

```nix
# flake.nix (simplified)
hostDirs = builtins.readDir ./hosts;
hostSystems = mapAttrs (name: _: import ./hosts/${name}/system.nix) hostDirs;
nixosHosts = filterAttrs (name: system: system == "x86_64-linux") hostSystems;
darwinHosts = filterAttrs (name: system: system == "aarch64-darwin") hostSystems;
```

## File Structure

Each host directory should contain:

```text
hosts/myhost/
  system.nix          # Required: system type string
  configuration.nix   # Required: main host configuration
  disko.nix           # Optional: disk layout (if using disko)
  hardware.nix        # Optional: hardware-specific settings
  ssh.nix             # Optional: SSH configuration
  network.nix         # Optional: network configuration
```

### system.nix

Returns the system type as a string:

```nix
# Linux (Intel/AMD 64-bit)
"x86_64-linux"

# macOS (Apple Silicon)
"aarch64-darwin"
```

## System Types

| System Type        | Description            |
| ------------------ | ---------------------- |
| `"x86_64-linux"`   | 64-bit Intel/AMD Linux |
| `"aarch64-darwin"` | Apple Silicon macOS    |

## Profiles

Hosts can import shared profiles from `modules/profiles/`:

- **workstation.nix** - Full desktop stack (niri, ashell, gaming, audio, bluetooth)
- **laptop.nix** - Power management, TLP, thermald, battery thresholds
- **server.nix** - Headless server defaults (no desktop, no gaming, no audio)

Profiles set `lib.mkDefault` values, so hosts can override any setting.

## Examples

### Workstation (Desktop)

```nix
# hosts/myhost/configuration.nix
{ ... }: {
  imports = [
    ../common.nix
    ../../modules/profiles/workstation.nix
    ./disko.nix
    ./hardware.nix
    ./ssh.nix
  ];

  mySystem = {
    gaming = {
      cpuBoostFreq = 5756452;
      cpuBaseFreq = 4500000;
    };
  };
}
```

### Laptop

```nix
# hosts/myhost/configuration.nix
{ ... }: {
  imports = [
    ../common.nix
    ../../modules/profiles/workstation.nix
    ../../modules/profiles/laptop.nix
    ./hardware.nix
    ./ssh.nix
  ];
}
```

### Server (Headless)

```nix
# hosts/myhost/configuration.nix
{ ... }: {
  imports = [
    ../common.nix
    ../../modules/profiles/server.nix
    ./disko.nix
    ./ssh.nix
  ];

  networking.hostName = "myhost";
  services.plex.enable = true;
}
```

### Darwin (macOS)

```nix
# hosts/myhost/configuration.nix
{ ... }: {
  imports = [
    # Darwin-specific imports
  ];
}
```

### ISO (Recovery/Live)

```nix
# hosts/myhost/configuration.nix
{ ... }: {
  # Minimal config for live ISO
  services.openssh.enable = true;
  # ...
}
```

ISO hosts are automatically buildable via
`nix build .#nixosConfigurations.<name>.config.system.build.isoImage`.

## Deployment

### Local

```bash
nh os switch .#myhost
```

### Remote (nixos-anywhere)

```bash
nix run github:nix-community/nixos-anywhere -- \
  --flake .#myhost \
  root@<ip>
```

### VM (Test Build)

```bash
nix build .#nixosConfigurations.myhost.config.system.build.vmWithDisko
```

## Updating lib/user.nix

If the new host needs SSH access, add its public key to `lib/user.nix`:

```nix
sshKeys = {
  ninja = "ssh-ed25519 AAAA...";
  mac = "ssh-ed25519 AAAA...";
  myhost = "ssh-ed25519 AAAA...";  # Add this
};
```

## Updating .sops.yaml

If the new host needs secrets, add a creation rule to `.sops.yaml`:

```yaml
creation_rules:
  - path_regex: secrets/myhost\.yaml$
    key_groups:
      - age:
          - *user_ninja
          - *user_mac
          - *host_myhost
```

## Troubleshooting

**Host not detected:** Make sure `system.nix` exists and returns a valid system type string.

**Build fails:** Check that all imports in `configuration.nix` are correct and that required files
(e.g., `disko.nix`) exist.

**Secrets not decrypting:** Verify the host's SSH key is in `.sops.yaml` and that `sops-nix` is
configured in the host's `configuration.nix`.

## See Also

- [Disko Rebuild Guide](disko-rebuild.md) - Disk layout and disaster recovery
- [Security & Hardening](security.md) - Security practices
- [Secrets Management](secrets.md) - sops-nix configuration
- [Hardware Notes](hardware.md) - ninja hardware details
