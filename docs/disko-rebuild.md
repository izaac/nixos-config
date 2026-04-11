# System Rebuild: Ninja Recovery with Disko

Complete disaster-recovery guide for the `ninja` workstation — from building the rescue ISO to a fully working system.

## 1. Build the Recovery ISO

The flake includes a minimal recovery image called **monko-canoe**. It has NetworkManager (with iwd for WiFi), firmware blobs, disk tools, and your user account — no desktop environment.

```bash
# From any machine with Nix installed
nix build github:izaac/nixos-config#iso

# Or from a local checkout
nix build .#iso
```

The resulting ISO is at `result/iso/nixos-*.iso`. Flash it to a USB drive:

```bash
sudo dd if=result/iso/nixos-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

## 2. Boot and Connect

1. Boot the target machine from the USB drive (UEFI mode, Secure Boot off).
2. Log in as your user — the ISO includes your account from `users/izaac/`.
3. Network should auto-connect via DHCP on Ethernet.
4. For WiFi:

   ```bash
   nmcli device wifi list
   nmcli device wifi connect "SSID" --ask
   ```

5. Verify connectivity:

   ```bash
   ping -c 3 github.com
   ```

## 3. Partition with Disko

The `disko` configuration uses stable `/dev/disk/by-id/` paths, so it targets the correct drives regardless of boot order.

### Dry-Run (Verification)

Preview what disko will do without touching any disks:

```bash
nix run github:nix-community/disko -- --dry-run --flake github:izaac/nixos-config#ninja
```

### Execute

**Warning: This destroys all data on the target disks.**

```bash
nix run github:nix-community/disko -- --mode destroy,format,mount --flake github:izaac/nixos-config#ninja
```

You will be prompted for a LUKS passphrase. This command will:

- Partition the primary NVMe (Crucial T705 1TB) with a 1GB ESP and a LUKS-encrypted EXT4 root.
- Partition the secondary NVMe (WD BLACK SN850X 4TB) as unencrypted EXT4 for `/mnt/data`.
- Mount everything under `/mnt`.

### Verify Mounts

```bash
lsblk
# Expected:
# nvme0n1       (Crucial T705)
# ├─nvme0n1p1   /mnt/boot  (vfat, 1G)
# └─nvme0n1p2   LUKS
#   └─luks-...  /mnt       (ext4)
# nvme1n1       (WD BLACK SN850X)
# └─nvme1n1p1   /mnt/mnt/data (ext4)
```

## 4. Install NixOS

```bash
nixos-install --flake github:izaac/nixos-config#ninja --no-root-password
```

This pulls the full `ninja` configuration from GitHub including NVIDIA drivers, COSMIC desktop, all packages, and Home Manager config. Set the user password when prompted.

## 5. Post-Installation

1. Reboot and remove the USB drive.
2. Enter your LUKS passphrase at the boot prompt.
3. Log in to COSMIC desktop.

### Restore SOPS Secrets

SOPS secrets require your age key or YubiKey to decrypt:

```bash
# Option A: age key file
mkdir -p ~/.config/sops/age
# Copy your age key from backup to ~/.config/sops/age/keys.txt

# Option B: YubiKey
# Just plug it in — sops-nix will use it automatically if configured
```

Verify secrets are working:

```bash
sudo cat /run/secrets/some-secret  # should show decrypted content
```

### Rebuild to Apply Secrets

```bash
cd ~/nixos-config  # or clone: git clone git@github.com:izaac/nixos-config.git
nrb  # nh os switch .
```

## Testing with vmWithDisko

Before touching real hardware, validate the entire disko layout in a virtual machine. This builds disk images in a VM, formats them with disko, and produces a bootable QEMU script.

### Build the VM

```bash
nix build .#nixosConfigurations.ninja.config.system.build.vmWithDisko
```

This creates virtual disk images matching the disko layout (LUKS, ESP, game drive) and a runner script.

### Run the VM

```bash
result/bin/run-ninja-vm
```

The VM will:

1. Create virtual disks mimicking your NVMe layout.
2. Run the full disko destroy → format → mount sequence.
3. Boot into the resulting NixOS system.

> **Note**: NVIDIA drivers are force-disabled in the VM via `virtualisation.vmVariant` in `configuration.nix`, so the VM uses software rendering. This is expected.

### What to Verify

- LUKS prompt appears and accepts the passphrase.
- System boots to login.
- `lsblk` shows the expected partition layout.
- `mount | grep -E "/ |/boot|/mnt/data"` shows correct mount options.

### Clean Up

The VM creates disk images in the current directory. Remove them after testing:

```bash
rm -f ninja.qcow2
```

## Disk Layout Reference

| Disk            | Device ID                                  | Size | Partition   | Format | Mount       | Encrypted |
| --------------- | ------------------------------------------ | ---- | ----------- | ------ | ----------- | --------- |
| Crucial T705    | `nvme-CT1000T705SSD3_2404E8929D13`         | 1TB  | ESP (1G)    | vfat   | `/boot`     | No        |
|                 |                                            |      | Root (rest) | ext4   | `/`         | LUKS      |
| WD BLACK SN850X | `nvme-WD_BLACK_SN850X_4000GB_24032G801549` | 4TB  | Data (100%) | ext4   | `/mnt/data` | No        |

The NFS mount (`/mnt/storage` → `192.168.0.173:/storage`) is defined in `hardware.nix` and auto-mounts on access after the system is running.

## How It Works

Disko owns all local disk mounts (`/`, `/boot`, `/mnt/data`). The `hardware.nix` file only declares hardware modules (kernel modules, microcode, kernel params) and the NFS network mount (`/mnt/storage`), which disko does not manage. Disko is always the single source of truth for local disk layout.
