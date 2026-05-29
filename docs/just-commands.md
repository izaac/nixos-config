# Just: The Jungle Magic Stick

The `just` command runner provides a simplified interface for common repository tasks. Instead of remembering complex Nix or NH commands, use these short-codes.

## Usage

Run any command from the root of the repository:

```bash
just <command>
```

## Available Commands

| Command                  | Description                        | Equivalent Action                                                       |
| :----------------------- | :--------------------------------- | :---------------------------------------------------------------------- |
| `just build`             | Rebuild and switch system          | `nh os switch .`                                                        |
| `just dry-build`         | Dry-run system build               | `nh os switch . -- --dry-run`                                           |
| `just iso`               | Build the Travel-Canoe (ISO)       | `nix build .#iso`                                                       |
| `just check`             | Run flake checks (treefmt)         | `nix flake check`                                                       |
| `just fmt`               | Format all files (treefmt)         | `nix fmt`                                                               |
| `just vm`                | Build and prep the Ghost-Cave      | `nix build .#nixosConfigurations.ninja.config.system.build.vmWithDisko` |
| `just clean`             | Remove old system generations      | `nh clean all --keep 5`                                                 |
| `just up`                | Update flake and system            | `nix flake update && nh os switch . --update`                           |
| `just deploy-ninja <ip>` | Install NixOS on remote machine    | `nix run github:nix-community/nixos-anywhere`                           |
| `just test-host <host>`  | Build a host's closure, no apply   | `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`   |
| `just builder-info`      | Show offload build machines        | `cat /etc/nix/machines`                                                 |
| `just builder-reset`     | Recreate Mac builder VM disk (Mac) | `launchctl bootout/bootstrap + rm nixos.qcow2`                          |

> **`test-host` + the Mac builder:** running `just test-host ninja` on the Mac
> builds ninja's whole closure and offloads the Linux build to the
> [linux-builder](linux-builder.md). A green build means the config evaluates and
> every package compiles — safe to apply on ninja. See the builder doc for the
> when/why and the disk-recreation gotcha behind `builder-reset`.

## Remote Installation (nixos-anywhere)

The `deploy-ninja` command uses `nixos-anywhere` to bootstrap a new machine over SSH.

- **Requirement**: The target machine must have an existing Linux install with SSH access as `root`.
- **Warning**: This command will **entirely wipe the destination disk** using the `disko` configuration.
- **RAM**: The target needs at least 1.5GB of RAM to host the temporary installer.

To add more commands, edit the `justfile` in the repository root. Remember to use tabs for indentation, as `just` follows `make` syntax.
