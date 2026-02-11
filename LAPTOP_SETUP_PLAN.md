# Laptop Setup Plan - Multi-Host Configuration

**Date:** 2026-02-10
**Current Host:** ninja (AMD desktop gaming rig)
**New Host:** laptop (Intel CPU + NVIDIA hybrid graphics)

## Overview

Transitioning from single-host to multi-host configuration using **profiles approach** since laptop has different requirements from desktop gaming rig.

---

## Key Differences: Desktop vs Laptop

| Feature | Ninja (Desktop) | Laptop |
|---------|----------------|--------|
| **CPU** | AMD Ryzen 9 9950X3D | Intel |
| **Graphics** | NVIDIA only | Hybrid (Intel iGPU + NVIDIA dGPU) |
| **Power** | Performance tuning | Battery management (TLP) |
| **Sleep** | Disabled (causes freezes) | Enabled (needed for laptop) |
| **Gaming** | Heavy optimization | Light/optional |
| **NVIDIA PRIME** | Not needed | **REQUIRED** for hybrid graphics |
| **Kernel** | Latest unstable | Stable (better battery life) |
| **Swappiness** | 180 (aggressive ZRAM) | Lower (preserve battery) |

---

## Information Needed from Laptop

### 1. Hardware Configuration

On the new laptop, run:
```bash
nixos-generate-config --show-hardware-config > /tmp/hardware.nix
cat /tmp/hardware.nix
```

Copy the output and provide it.

### 2. System Information

```bash
# NVIDIA GPU model
lspci | grep -i nvidia

# CPU model
lscpu | grep "Model name"

# Network interfaces
ip link show
```

### 3. Laptop Preferences

**Questions to answer:**
- Laptop hostname? (e.g., "laptop", "thinkpad", "xps")
- Install KDE Plasma desktop? (Y/N)
- Install development tools? (Git, VSCode, direnv, etc.) (Y/N)
- Install gaming tools? (Steam, Heroic, Lutris) (Y/N - probably lighter setup)
- Install distrobox containers? (Y/N)
- Any specific software needs?

---

## Planned Repository Structure

### Current Structure
```
nixos-config/
├── flake.nix                    # Single host (ninja)
├── hosts/ninja/                 # Desktop config
├── modules/                     # Shared modules
└── home/                        # Monolithic home config (18 files)
```

### New Structure (After Refactor)
```
nixos-config/
├── flake.nix                    # Multi-host with mkHost helper
├── hosts/
│   ├── ninja/                   # Desktop gaming rig
│   │   ├── configuration.nix
│   │   ├── hardware.nix
│   │   ├── nvidia.nix
│   │   └── network.nix
│   └── laptop/                  # NEW: Laptop
│       ├── configuration.nix    # Intel CPU, TLP, suspend
│       ├── hardware.nix         # Generated config
│       ├── nvidia-prime.nix     # Hybrid graphics
│       └── network.nix          # Laptop networking
├── modules/                     # Shared modules (unchanged)
│   ├── core/
│   ├── desktop/
│   └── gaming/
└── home/
    ├── common.nix               # NEW: Shared configs
    ├── profiles/
    │   ├── desktop.nix          # NEW: Gaming desktop profile
    │   └── laptop.nix           # NEW: Laptop profile
    └── modules/                 # Individual module files
        ├── shell.nix
        ├── dev.nix
        ├── kitty.nix
        └── ... (all existing files)
```

---

## Implementation Steps

### Phase 1: Home Config Refactor (Desktop First)

Split monolithic home config into common + profiles:

1. **Create `home/common.nix`**
   - Shell (bash, aliases, starship)
   - Core tools (git, tmux, vim, direnv)
   - Terminal (kitty)
   - SSH config
   - Common apps

2. **Create `home/profiles/desktop.nix`**
   - Gaming (Steam, Heroic, Lutris, MangoHUD)
   - Full KDE Plasma config
   - Desktop apps (Firefox, Telegram, VLC)
   - Distrobox containers
   - Development (VSCode, LSPs)

3. **Create `home/profiles/laptop.nix`**
   - Lighter KDE Plasma (or skip?)
   - Development tools
   - Optional light gaming
   - Browser, media
   - Battery-friendly settings

### Phase 2: Flake Refactor

Extract common configuration and create `mkHost` helper:

```nix
let
  # Common modules for all hosts
  commonModules = [
    home-manager.nixosModules.home-manager
    {
      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [
        (import ./overlays/sparrow-temurin-fix.nix)
        (import ./overlays/unstable-packages.nix pkgs-unstable)
        (import ./overlays/kde-unstable.nix)
        claude-code.overlays.default
      ];
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.backupFileExtension = "hm-backup";
      home-manager.extraSpecialArgs = { inherit inputs userConfig; };
    }
  ];

  # Helper to create a host with a specific home profile
  mkHost = hostname: profile: nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = { inherit inputs userConfig; };
    modules = [
      ./hosts/${hostname}/configuration.nix
      {
        home-manager.users.${userConfig.username} = {
          imports = [
            ./home/profiles/${profile}.nix
            plasma-manager.homeModules.plasma-manager
          ];
        };
      }
    ] ++ commonModules;
  };
in {
  nixosConfigurations = {
    ninja = mkHost "ninja" "desktop";
    laptop = mkHost "laptop" "laptop";
  };
}
```

### Phase 3: Laptop Host Config

**Key laptop-specific settings:**

```nix
# hosts/laptop/configuration.nix
{
  # Intel CPU optimizations
  boot.kernelParams = [
    "intel_pstate=active"
    # Remove AMD-specific params
  ];

  # Stable kernel for battery life
  boot.kernelPackages = pkgs.linuxPackages;

  # Battery management
  services.tlp.enable = true;
  services.power-profiles-daemon.enable = false;

  # Enable suspend/hibernate (unlike desktop)
  systemd.targets.sleep.enable = true;
  systemd.targets.suspend.enable = true;
  systemd.targets.hibernate.enable = true;

  # Lower swappiness for battery
  boot.kernel.sysctl."vm.swappiness" = 60;  # vs 180 on desktop

  # Import laptop modules
  imports = [
    ./hardware.nix
    ./nvidia-prime.nix  # Hybrid graphics
    ./network.nix
    ../../modules/core/nix-ld.nix
    ../../modules/core/codecs.nix
    ../../modules/core/bluetooth-audio.nix
    ../../modules/desktop/default.nix
    # Optional: ../../modules/gaming/default.nix (lighter setup)
  ];
}
```

**NVIDIA PRIME Config:**

```nix
# hosts/laptop/nvidia-prime.nix
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;  # Important for laptop
    powerManagement.finegrained = false;
    open = false;  # Use proprietary for better hybrid support
    nvidiaSettings = true;

    # PRIME configuration
    prime = {
      # Find with: lspci | grep -E 'VGA|3D'
      intelBusId = "PCI:0:2:0";    # REPLACE with actual
      nvidiaBusId = "PCI:1:0:0";   # REPLACE with actual

      # Choose sync or offload mode:
      # sync.enable = true;          # Always use NVIDIA (more power)
      offload.enable = true;         # Use Intel, offload to NVIDIA when needed
      offload.enableOffloadCmd = true;  # Provides nvidia-offload command
    };
  };

  # Environment variables for hybrid graphics
  environment.sessionVariables = {
    __NV_PRIME_RENDER_OFFLOAD = "1";
    __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __VK_LAYER_NV_optimus = "NVIDIA_only";
  };
}
```

---

## Commands to Run on Laptop

### Initial Setup (Vanilla NixOS)

1. **Install NixOS** (standard installation)

2. **Generate hardware config:**
   ```bash
   nixos-generate-config --show-hardware-config > /tmp/hardware.nix
   cat /tmp/hardware.nix  # Copy this
   ```

3. **Gather system info:**
   ```bash
   lspci | grep -i vga      # Get bus IDs
   lspci | grep -i nvidia   # Get NVIDIA model
   lscpu | grep "Model"     # CPU info
   ```

### After Config is Ready

4. **Clone repo on laptop:**
   ```bash
   git clone <your-repo-url> ~/nixos-config
   cd ~/nixos-config
   git pull origin main  # Get latest changes
   ```

5. **Build and switch:**
   ```bash
   # Test build first
   sudo nixos-rebuild build --flake .#laptop

   # If successful, switch
   sudo nixos-rebuild switch --flake .#laptop
   ```

6. **Reboot:**
   ```bash
   sudo reboot
   ```

---

## Testing NVIDIA PRIME on Laptop

After setup, test hybrid graphics:

```bash
# Check if PRIME is working
nvidia-smi  # Should show GPU

# Run app with NVIDIA offload
nvidia-offload glxinfo | grep "OpenGL renderer"

# Should show NVIDIA GPU, not Intel
```

---

## Aliases for Laptop

Same aliases will work:
- `nrb` - Rebuild and switch
- `ndr` - Dry-run build (no sudo)
- `up` - Update and switch
- `ncl` - Clean old generations

---

## Next Steps

1. ✅ Save this plan
2. ⏳ Boot into laptop
3. ⏳ Run hardware detection commands
4. ⏳ Provide info to Claude
5. ⏳ Claude creates laptop config + refactors home profiles
6. ⏳ Test and deploy

---

## Notes

- Keep this file in the repo root for easy reference
- Update as needed during implementation
- Can be deleted after successful laptop setup
- Or keep as documentation for adding future hosts

---

**Status:** Planning phase - waiting for laptop hardware info
