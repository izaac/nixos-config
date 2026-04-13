# CLI Tools and Command Integration

This repository integrates several modern, Rust-based CLI utilities designed to improve performance and safety compared to traditional GNU coreutils.

## The Comma Utility (`,`)

The `comma` tool (a wrapper for `nix-index`) allows for the execution of software without requiring a permanent installation in the user environment. This is ideal for one-off tasks or testing new packages.

### Usage

Prepend any command with a comma to execute it via Nix:

```bash
, cowsay "Hello from Nix"
```

**Mechanism:** `comma` queries the Nix package index to identify the correct package for the requested binary, downloads it to the Nix store temporarily, executes the command, and ensures the environment remains uncluttered.

## Core Utility Replacements

The following tools are integrated and aliased by default:

- **`rip` (rm-improved):** A safe replacement for `rm`. Instead of immediate deletion, files are moved to a temporary "shredder" directory from which they can be recovered.
- **`bat`:** A replacement for `cat` that provides syntax highlighting and Git integration.
- **`eza`:** A feature-rich replacement for `ls` with support for icons, color formatting, and integrated Git status.
- **`zoxide` (`z`):** A smart directory jumper that learns your most-used paths to enable rapid navigation.
- **`btop`:** A graphical system monitor for real-time tracking of CPU, memory, and network usage.
- **`yazi` (`y`):** A terminal-based file manager with high-performance image previews and intuitive navigation.

## Nix Package Maintenance

### nix-update

Automatically bumps package versions and hashes for packages defined in a flake. Works with standard `callPackage` packages in `nix-packages`.

```bash
cd ~/nix-packages

# Auto-detect latest version and update
nix-update --flake ethereal-waves

# Pin to a specific version
nix-update --flake --version=0.4.0 brush-shell
```

**Limitations:** Does not work with inline overlays (e.g., `overlays/sparrow-temurin-fix.nix`). Only works with packages that have a discoverable upstream (GitHub releases, PyPI, etc.).

### nurl

Generates Nix fetcher calls (with hashes) from repository URLs. Useful when adding new packages or manually updating overlays.

```bash
# Generate fetchFromGitHub expression
nurl https://github.com/reubeno/brush v0.3.1

# Generate fetchurl hash for a release tarball
nurl https://github.com/sparrowwallet/sparrow/releases/download/2.5.0/sparrowwallet-2.5.0-x86_64.tar.gz
```

**Workflow for overlay updates (e.g., Sparrow):**

1. Get the new hash: `nurl https://github.com/sparrowwallet/sparrow <new-version>`
2. Update version and hash in the overlay file manually
3. Rebuild: `nh os build .`

## Shell Configuration Validation

The `home/shell.nix` file is complex and contains many embedded bash functions. To ensure changes do not introduce syntax errors that could break the login shell, use the following validation command:

```bash
nix eval ".#nixosConfigurations.$(hostname).config.home-manager.users.$USER.programs.bash.initExtra" \
  --extra-experimental-features dynamic-derivations --raw | bash -n
```

This command evaluates the Nix expression, extracts the raw bash content, and pipes it through `bash -n` to perform a syntax check without executing the code.
