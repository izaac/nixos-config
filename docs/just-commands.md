# Just: The Jungle Magic Stick

The `just` command runner provides a simplified interface for common repository tasks. Instead of remembering complex Nix or NH commands, use these short-codes.

## Usage

Run any command from the root of the repository:
```bash
just <command>
```

## Available Commands

| Command | Description | Equivalent Action |
| :--- | :--- | :--- |
| `just build` | Rebuild and switch system | `nh os switch .` |
| `just dry-build` | Dry-run system build | `nh os switch . -- --dry-run` |
| `just iso` | Build the Travel-Canoe (ISO) | `nix build .#iso` |
| `just check` | Run flake checks and linting | `nix flake check && statix check .` |
| `just vm` | Build and prep the Ghost-Cave | `nix build .#nixosConfigurations.ninja.config.system.build.vmWithDisko` |
| `just clean` | Remove old system generations | `nh clean all --keep 5` |
| `just up` | Update flake and system | `nix flake update && nh os switch . --update` |

## Adding New Magic

To add more commands, edit the `justfile` in the repository root. Remember to use tabs for indentation, as `just` follows `make` syntax.
