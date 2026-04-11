# System Rebuild: Ninja Recovery with Disko

This guide outlines the procedure for a complete "from scratch" rebuild of the `ninja` workstation using the declarative `disko` layout.

## 1. Prerequisites

- A bootable NixOS installation media (preferably the custom **Travel-Canoe ISO** built from this flake).
- Access to this repository (GitHub) and any necessary decryption keys for SOPS (e.g., your age key or YubiKey).

## 2. Booting and Preparation

1. Boot the target machine into the NixOS Live environment.
2. Ensure you have a working network connection (Ethernet is preferred for zero-latency downloads).
3. If using the custom ISO, your SSH keys and basic environment will already be present.

## 3. Declarative Disk Partitioning (Disko)

The `disko` configuration for `ninja` is designed to match the existing hardware layout exactly, using persistent disk IDs to ensure safety.

### Dry-Run (Verification)

Before carving any physical disks, verify what Disko intends to do:

```bash
nix run github:nix-community/disko -- --dry-run --flake github:izaac/nixos-config#ninja
```

### Execution

Once verified, run the formatting and partitioning logic. **Warning: This will destroy all data on the target disks.**

```bash
nix run github:nix-community/disko -- --mode destroy,format,mount --flake github:izaac/nixos-config#ninja
```

This command will:

- Partition the primary NVMe drive (CT1000T705SSD3) with a 1GB ESP and a LUKS container.
- Open the LUKS container and format it with EXT4.
- Partition the secondary NVMe drive (WD_BLACK_SN850X) for games.
- Mount the entire structure to `/mnt` (including `/mnt/boot` and `/mnt/mnt/data`).

## 4. System Installation

With the disks mounted at `/mnt`, trigger the NixOS installation process:

```bash
nixos-install --flake github:izaac/nixos-config#ninja
```

## 5. Post-Installation

1. Reboot the system and remove the installation media.
2. On first boot, provide your LUKS passphrase.
3. Once in the system, ensure your SOPS secrets are working:

   ```bash
   # Re-import age keys if necessary
   mkdir -p ~/.config/sops/age
   # Copy your key here or use sops with your YubiKey
   ```

4. Run the initial maintenance tasks:

   ```bash
   nrb  # nh os switch .
   ```

## How It Works

Disko owns all local disk mounts (`/`, `/boot`, `/mnt/data`). The `hardware.nix` file only declares hardware modules (kernel modules, microcode, kernel params) and the NFS network mount (`/mnt/storage`), which disko does not manage. There is no conditional guard — disko is always the single source of truth for local disk layout.
