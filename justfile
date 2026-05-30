# --- JUNGLE MAGIC COMMANDS ---

# Show available commands
default:
        @just --list

# Build the system for macOS (drb alias)
darwin-build:
        sudo -H darwin-rebuild switch --flake .#Mac

# Build the system (nrb alias)
build:
        nh os switch .

# Dry-run build (match old ndr behavior)
dry-build:
        nix build .#nixosConfigurations.$(hostname).config.system.build.toplevel --dry-run

# Build the Travel-Canoe (minimal ISO)
iso:
        nix build .#iso

# Build the Travel-Canoe with niri desktop (live ISO)
iso-niri:
        nix build .#iso-niri -o result-niri

# Run the Magic Eye (Checks)
check:
        nix flake check

# Format all stones (treefmt)
fmt:
        nix fmt

# Ghost Cave (VM with Disko)
vm:
        nix build .#nixosConfigurations.ninja.config.system.build.vmWithDisko --no-link --print-out-paths
        # To run: ./result/bin/run-ninja-vm

# Clear the jungle (Cleanup)
clean:
        nh clean all --keep 5

# Update the whole jungle (Flake Update)
up:
        nix flake update
        nh os switch . --update

# Update only browser inputs and switch
up-browsers:
        nix flake update nixpkgs
        nh os switch .

# Activate git pre-commit hooks
setup-hooks:
        git config core.hooksPath .githooks
        @echo "Git hooks activated (.githooks/pre-commit)"

# Deploy Ninja brain to a remote IP via SSH (WIPES DISK!)
deploy-ninja ip:
        nix run github:nix-community/nixos-anywhere -- --flake .#ninja root@{{ip}}

# Test-build a host's full closure WITHOUT applying — validates eval + build.
# On the Mac this offloads the Linux build to the linux-builder VM.
test-host host:
        nix build .#nixosConfigurations.{{host}}.config.system.build.toplevel --no-link --print-out-paths

# Show the build machines this host can offload to (Mac: the linux-builder)
builder-info:
        @cat /etc/nix/machines 2>/dev/null || echo "No /etc/nix/machines — no remote/linux builder configured."

# Recreate the Mac linux-builder VM disk to apply nix.linux-builder.config changes (Mac-only)
builder-reset:
        sudo launchctl bootout system/org.nixos.linux-builder || true
        sudo rm -f /var/lib/linux-builder/nixos.qcow2
        sudo launchctl bootstrap system /Library/LaunchDaemons/org.nixos.linux-builder.plist
        @echo "Builder disk recreated — it reseeds from the image on next build."
