# Linux Builder (Mac)

> **Host**: `Mac` (Apple Silicon, arm64)
> **Defined in**: [`hosts/Mac/configuration.nix`](../hosts/Mac/configuration.nix) — `nix.linux-builder`

A local NixOS virtual machine (Apple Virtualization framework) that lets the
arm64 Mac **build Linux Nix closures** without a remote build server. Nix
automatically offloads any Linux derivation to it.

---

## What it is

- A small headless NixOS VM, managed by launchd (`org.nixos.linux-builder`).
- Registered as a build machine in `/etc/nix/machines` as
  `ssh-ng://builder@linux-builder`.
- Builds **two systems**:

| System          | Speed               | How                                   |
| --------------- | ------------------- | ------------------------------------- |
| `aarch64-linux` | Native (fast)       | Same arch as the Mac                  |
| `x86_64-linux`  | Emulated (**slow**) | QEMU user-mode via `binfmt` in the VM |

---

## When to use it

**Use it for building/testing Linux Nix packages from the Mac:**

- Iterating on a NixOS module or a package from the `nix-packages` repo.
- Building a closure for the Linux hosts (`ninja`, `windy` — both `x86_64-linux`).
- Cross-checking that a change evaluates and builds on Linux before pushing.

**Do NOT use it for:**

- **Running** Linux GUI apps, browsers, or long-lived services. It is a build
  sandbox, not a general-purpose Linux VM or runtime.
- Anything that needs a Linux desktop. (Example: Playwright + Microsoft Edge —
  use the **native macOS Edge** instead; see the note at the bottom.)

> **Rule of thumb:** the builder _compiles_ Linux software. It does not _run_
> Linux applications interactively.

---

## How to use it

Nix routes Linux builds to the builder automatically — no flags needed. Just
ask for a Linux output:

```bash
# aarch64-linux — native speed in the VM
nix build nixpkgs#legacyPackages.aarch64-linux.hello

# x86_64-linux — works, but emulated and slow
nix build nixpkgs#legacyPackages.x86_64-linux.hello

# Build a closure for one of the Linux hosts (x86_64-linux)
nix build .#nixosConfigurations.ninja.config.system.build.toplevel
```

**Confirm it offloaded** — look for this line in the build log:

```text
building '/nix/store/….drv' on 'ssh-ng://builder@linux-builder'...
```

---

## Workflow summary

| Goal                       | Command / check                                                       |
| -------------------------- | --------------------------------------------------------------------- |
| Build a Linux package      | `nix build nixpkgs#legacyPackages.<system>.<pkg>`                     |
| Build a Linux host closure | `nix build .#nixosConfigurations.<host>.config.system.build.toplevel` |
| Confirm offload happened   | Look for `on 'ssh-ng://builder@linux-builder'` in the log             |
| Check advertised systems   | `cat /etc/nix/machines`                                               |
| Restart the VM             | `sudo launchctl kickstart -k system/org.nixos.linux-builder`          |

---

## Gotcha: config changes need a disk recreation

The VM boots a **persistent disk** at `/var/lib/linux-builder/nixos.qcow2`,
seeded once from the VM image. Changing `nix.linux-builder.config` (for example
`boot.binfmt.emulatedSystems`) and running `darwin-rebuild switch` updates the
host-side launchd job **but not the already-seeded disk** — the VM keeps booting
the old guest system.

To apply a guest-config change, recreate the disk (safe and self-healing — it
just re-copies cached store paths on the next build):

```bash
sudo launchctl bootout system/org.nixos.linux-builder
sudo rm -f /var/lib/linux-builder/nixos.qcow2
sudo launchctl bootstrap system /Library/LaunchDaemons/org.nixos.linux-builder.plist
```

The fresh `nixos.qcow2` is reseeded from the updated image. A plain
`systems`/`maxJobs` change (host-side only) does **not** need this — just switch.

---

## Costs & caveats

- **x86_64 builds are slow.** QEMU user-mode emulation; use only when you must
  produce x86_64 output. Prefer pulling from `cache.nixos.org` when possible.
- **The VM disk grows** as store paths accumulate. Reclaim space by recreating
  the disk (same commands as above).
- **Testing offload, never use `nix build --rebuild`.** That forces a _local_
  rebuild and reports a platform mismatch for foreign systems. To prove offload,
  build a fresh, uniquely-named derivation and watch for the
  `on 'ssh-ng://builder@linux-builder'` line.
