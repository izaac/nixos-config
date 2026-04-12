# --- JUNGLE MAGIC COMMANDS ---

# Build the system (nrb alias)
build:
	nh os switch .

# Dry-run build
dry-build:
	nh os switch . -- --dry-run

# Build the Travel-Canoe (ISO)
iso:
	nix build .#iso

# Run the Magic Eye (Checks)
check:
	nix flake check
	statix check .

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

# Deploy Ninja brain to a remote IP via SSH (WIPES DISK!)
deploy-ninja ip:
	nix run github:nix-community/nixos-anywhere -- --flake .#ninja root@{{ip}}
