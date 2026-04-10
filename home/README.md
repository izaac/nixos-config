# Home Manager Layout

- `core.nix`: shared baseline modules for the user session
- `desktop.nix`: desktop app stack and GNOME user settings
- `gaming.nix`: gaming tools and launchers
- `dev.nix`: development toolchain and git/direnv setup

Composition order:

1. `modules/core/home-manager.nix` enables Home Manager and imports `home/core.nix`.
2. `users/izaac/default.nix` layers user role modules (`home/desktop.nix`, `home/gaming.nix`).
