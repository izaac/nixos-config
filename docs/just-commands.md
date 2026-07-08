# Just: The Jungle Magic Stick

The `just` command runner provides a simplified interface for common repository tasks. Instead of remembering complex Nix or NH commands, use these short-codes.

## Usage

Run any command from the root of the repository:

```bash
just <command>
```

## Available Commands

| Command                                 | Description                                 | Equivalent Action                                                       |
| :-------------------------------------- | :------------------------------------------ | :---------------------------------------------------------------------- |
| `just build`                            | Rebuild and switch (darwin-aware)           | `nh os switch .` (Linux) / `just darwin-build` (macOS)                  |
| `just darwin-build`                     | Rebuild and switch the Mac                  | `sudo -H darwin-rebuild switch --flake .#Mac`                           |
| `just dry-build`                        | Eval current host's closure, no build       | `nix build .#nixosConfigurations.$(hostname)...toplevel --dry-run`      |
| `just iso`                              | Build the Travel-Canoe (minimal ISO)        | `nix build .#iso`                                                       |
| `just iso-niri`                         | Build the niri desktop ISO                  | `nix build .#iso-niri`                                                  |
| `just check`                            | Run flake checks (treefmt)                  | `nix flake check`                                                       |
| `just fmt`                              | Format all files (treefmt)                  | `nix fmt`                                                               |
| `just vm`                               | Build and prep the Ghost-Cave               | `nix build .#nixosConfigurations.ninja.config.system.build.vmWithDisko` |
| `just clean`                            | Remove old system generations               | `nh clean all --keep 5`                                                 |
| `just up`                               | Update all flake inputs and switch          | `nix flake update && nh os switch . --update`                           |
| `just up-nixpkgs`                       | Update only nixpkgs (full channel) + switch | `nix flake update nixpkgs && nh os switch .`                            |
| `just setup-hooks`                      | Activate git pre-commit hooks               | `git config core.hooksPath .githooks`                                   |
| `just validate-sudo`                    | Check sudo-readonly ruleset                 | `scripts/validate-sudo.sh`                                              |
| `just road-on / road-off / road-status` | Hostile-network lockdown toggle             | `scripts/road-mode.sh on/off/status`                                    |
| `just road-test`                        | Run road-mode unit tests                    | `scripts/tests/road-mode-test.sh`                                       |
| `just deploy-ninja <ip>`                | Install NixOS on remote machine             | `nix run github:nix-community/nixos-anywhere`                           |
| `just test-host <host>`                 | Build a host's closure, no apply            | `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`   |
| `just builder-info`                     | Show offload build machines                 | `cat /etc/nix/machines`                                                 |
| `just builder-reset`                    | Recreate Mac builder VM disk (Mac)          | `launchctl bootout/bootstrap + rm nixos.qcow2`                          |

> **`test-host` + the Mac builder:** running `just test-host ninja` on the Mac
> builds ninja's whole closure and offloads the Linux build to the
> [linux-builder](linux-builder.md). A green build means the config evaluates and
> every package compiles, safe to apply on ninja. See the builder doc for the
> when/why and the disk-recreation gotcha behind `builder-reset`.

## Remote Installation (nixos-anywhere)

The `deploy-ninja` command uses `nixos-anywhere` to bootstrap a new machine over SSH.

- **Requirement**: The target machine must have an existing Linux install with SSH access as `root`.
- **Warning**: This command will **entirely wipe the destination disk** using the `disko` configuration.
- **RAM**: The target needs at least 1.5GB of RAM to host the temporary installer.

To add more commands, edit the `justfile` in the repository root. Remember to use tabs for indentation, as `just` follows `make` syntax.
