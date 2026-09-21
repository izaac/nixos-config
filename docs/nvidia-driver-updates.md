# Updating Custom NVIDIA Drivers in NixOS

> **Current state:** `windy` tracks `nvidiaPackages.stable` (open kernel modules), while `ninja`
> uses the `mkDriver` override pinned to **`615.71.09`** (New Feature Branch) to include Blackwell
> fixes for the RTX 5060 Ti. The `mkDriver` override below documents how this pin is maintained and
> bumped when nixpkgs lags upstream.

This guide explains how to pin an NVIDIA driver version using the `mkDriver` override when the
nixpkgs channel lags a release you need.

## 1. Where to Look for Updates

To find new driver versions, you can check the following sources:

- **NVIDIA Linux Driver Archive**:
  [https://www.nvidia.com/en-us/drivers/unix/](https://www.nvidia.com/en-us/drivers/unix/)
- **Vulkan Beta Drivers** (Often used for bleeding-edge gaming):
  [https://developer.nvidia.com/vulkan-driver](https://developer.nvidia.com/vulkan-driver)
- **NVIDIA Open Kernel Modules GitHub** (Important if using `open = true;`):
  [https://github.com/NVIDIA/open-gpu-kernel-modules/tags](https://github.com/NVIDIA/open-gpu-kernel-modules/tags)

_Note: Ensure that the version you select has matching tags in the `nvidia-settings` and
`nvidia-persistenced` GitHub repositories, as well as an available `.run` file on the NVIDIA CDN._

## 2. Locating the Configuration

The custom driver configuration is located in the NVIDIA specific module for the host (e.g.,
`hosts/ninja/nvidia.nix`). Look for the `package` definition under `hardware.nvidia`:

```nix
hardware.nvidia = {
  package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "615.71.09";
    sha256_64bit = "sha256-zc7tIrvrYSSNGm3qvCWWZz46ZQFpjucayNL9wo87cP4=";
    openSha256 = "sha256-3gByMYIwFzRaLdDG+roCEOuKRRJDrljG9AlLnRZTirM=";
    settingsSha256 = "sha256-LK1LU8mDkM/XVRKPBtuOZh9nIP/lGFLAJnmasEX8jhg=";
    persistencedSha256 = "sha256-qPRb+3d88+2RcpUkoBTbjIaImnQ+jX+/6p1vXcJ5geE=";
  };
};
```

## 3. How to Update and Generate Hashes

Nix strictly enforces checksums (SHA256) for all downloaded packages. When you bump the `version`
string, the URLs change, meaning the hashes will no longer match the new files.

There are two primary methods to generate the new hashes.

### Method A: The "Trust on First Use" (Fail & Copy) Method - Recommended

The easiest way to update is to intentionally fail the build and let Nix tell you the correct
hashes.

1. **Update the Version:** Change the `version` string in `nvidia.nix` to the new version (e.g.,
   `"595.xx.xx"`).
2. **Clear the Hashes:** Set all the hash fields to an empty string (`""` or `lib.fakeHash`).

   ```nix
   version = "595.xx.xx";
   sha256_64bit = "";
   sha256_aarch64 = "";
   openSha256 = "";
   settingsSha256 = "";
   persistencedSha256 = "";
   ```

3. **Rebuild the System:** Run your normal rebuild command.

   ```bash
   sudo nixos-rebuild switch --flake .#ninja
   ```

4. **Copy the Hashes:** The build will fail with a "hash mismatch" error for the first package it
   tries to download. It will show you an output like:

   ```text
   error: hash mismatch in fixed-output derivation '/nix/store/...':
     specified: sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
     got:       sha256-ActualCorrectHashGoesHere1234567890abcdefg=
   ```

5. **Paste and Repeat:** Paste the `got:` hash into the corresponding field in `nvidia.nix`. Run the
   rebuild command again. It will fail on the _next_ missing hash. Repeat this process until all 5
   hashes are filled in and the build succeeds.

### Method B: Pre-fetching the Hashes via CLI (Advanced)

If you prefer to get all the hashes up front without failing the rebuild multiple times, you can use
`nix-prefetch-url`.

Replace `VERSION` in the commands below with your target version (e.g., `590.44.01`). _Note: We pass
`--type sha256` to ensure it outputs a standard Nix hash._

**1. `sha256_64bit`** (The main driver `.run` file):

```bash
nix-prefetch-url https://download.nvidia.com/XFree86/Linux-x86_64/VERSION/NVIDIA-Linux-x86_64-VERSION.run
```

**2. `sha256_aarch64`** (The ARM driver `.run` file):

```bash
nix-prefetch-url https://download.nvidia.com/XFree86/Linux-aarch64/VERSION/NVIDIA-Linux-aarch64-VERSION.run
```

**3. `openSha256`** (The Open Kernel Modules source):

```bash
nix-prefetch-url --unpack https://github.com/NVIDIA/open-gpu-kernel-modules/archive/refs/tags/VERSION.tar.gz
```

**4. `settingsSha256`** (The nvidia-settings utility source):

```bash
nix-prefetch-url --unpack https://github.com/NVIDIA/nvidia-settings/archive/refs/tags/VERSION.tar.gz
```

**5. `persistencedSha256`** (The nvidia-persistenced utility source):

```bash
nix-prefetch-url --unpack https://github.com/NVIDIA/nvidia-persistenced/archive/refs/tags/VERSION.tar.gz
```

_Note: For the GitHub archives (`openSha256`, `settingsSha256`, `persistencedSha256`), we use
`--unpack` because Nix unpacks these repositories during the build process, and the hash represents
the unpacked contents._

## 4. Applying the Update

Once you have filled in the `version` and all 5 hashes, run your rebuild command:

```bash
sudo nixos-rebuild switch --flake .#ninja
```

If the screen goes black or you experience issues, you can always reboot and select the previous
NixOS generation from the boot menu.

## Troubleshooting

- **404 Errors on GitHub Packages:** Occasionally, NVIDIA might not publish an open-kernel-modules,
  settings, or persistenced tag at the exact same time as a beta/developer driver release. If
  `nix-prefetch-url` returns a 404, the version is not fully available across all necessary repos
  yet. You will have to wait, or use the last stable version.
- **aarch64 missing:** If the ARM64 driver is missing but you only use x86_64, you can usually leave
  the `sha256_aarch64` hash as a `fakeHash` (or the previous working hash), as Nix will only attempt
  to download and verify the x86_64 driver on your x86_64 machine.
