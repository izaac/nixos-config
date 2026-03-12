# NixOS Architecture Refactor Plan

This document outlines the planned "Next Level" architectural refactoring for the `nixos-config` repository, moving from a "Static Bundle" approach to a true "Options-Based Profile" architecture.

## 1. Decoupling System and User (The "Users" Directory)
**Current State:** System modules (`modules/gaming`, `modules/desktop`) forcefully inject Home Manager configurations into the user's home directory. This breaks multi-user scalability (e.g., a guest user getting personal shortcuts).
**Target State:**
*   Create a `users/` directory at the root (e.g., `users/izaac/default.nix`).
*   System modules (`modules/`) will ONLY handle root-level concerns (udev rules, systemd services, kernel modules, global packages).
*   User profiles (`users/izaac/`) will act as the entry point for Home Manager, importing configurations from `home/` (dotfiles, user packages, desktop entries).

## 2. Abstracting Flake Helpers (`lib/` expansion)
**Current State:** The `mkSystem` helper function is defined directly inside `flake.nix`, which will cause bloat as more hosts and architectures are added.
**Target State:**
*   Move `mkSystem` and any future generation logic into `lib/mkSystem.nix`.
*   `flake.nix` should act purely as a clean router/manifest.

## 3. Transition to True Modules (Custom Options)
**Current State:** Modules are imported as static bundles. Importing `modules/gaming` applies everything, making it difficult to disable specific sub-features on less powerful hosts (like `windy`).
**Target State:**
*   Wrap configurations in `lib.mkEnableOption` and `lib.mkIf`.
*   Host configurations (`hosts/*/configuration.nix`) will transition from file path imports to declarative feature flags.
*   **Example:**
    ```nix
    # Inside hosts/ninja/configuration.nix
    mySystem = {
      gaming = {
        enable = true;
        scxScheduler = true; # Enabled for 9950X3D
      };
      desktop.environment = "hyprland";
    };
    ```

## 4. Why make these changes?
*   **Scalability:** Safely add secondary users (guests, work profiles) without leaking dotfiles.
*   **Granularity:** Fine-tune features per-host without having to duplicate or fracture module files.
*   **Community Standard:** This aligns with the architecture used by complex, enterprise-grade Nix deployments.

---

## 🏗️ Staged Execution Plan

To ensure a smooth transition without breaking the current working setup, this refactor should be executed in three isolated, verifiable stages.

### Stage 1: Flake Abstraction (Low Risk)
*Goal: Clean up the entry point and establish the library foundation.*
1.  **Create Helper:** Move the `mkSystem` function from `flake.nix` into `lib/mkSystem.nix`.
2.  **Update Flake:** Refactor `flake.nix` to import `lib/mkSystem.nix` instead of defining it inline.
3.  **Validate:** Run `nix flake check` and `ndry`. The system state should not change at all (Zero rebuilds expected).

### Stage 2: User / System Decoupling (Medium Risk)
*Goal: Separate root-level module logic from user-level Home Manager dotfiles.*
1.  **Create Profile:** Create `users/izaac/default.nix` (or `home.nix`).
2.  **Migrate Imports:** Move all `home-manager.users.${userConfig.username}.imports = [...]` statements out of `modules/gaming/default.nix` and `modules/desktop/default.nix`.
3.  **Wire it up:** Place those imports into `users/izaac/default.nix`.
4.  **Host Update:** Update `hosts/ninja/configuration.nix` and `hosts/windy/configuration.nix` to import the new user profile directly.
5.  **Validate:** Run `nrb`. The environment should look identical, but the coupling is broken.

### Stage 3: Options-Based Modules (High Effort)
*Goal: Convert static bundles into configurable NixOS modules.*
1.  **Define Options:** In `modules/gaming/default.nix`, wrap the content in:
    ```nix
    { config, lib, pkgs, ... }:
    with lib;
    let cfg = config.mySystem.gaming;
    in {
      options.mySystem.gaming = { enable = mkEnableOption "Gaming Tools"; };
      config = mkIf cfg.enable { /* ... existing config ... */ };
    }
    ```
2.  **Apply Feature Flags:** Update `hosts/ninja/configuration.nix` to explicitly set `mySystem.gaming.enable = true;`.
3.  **Repeat:** Systematically apply this pattern to `modules/desktop`, `modules/core/audio.nix`, etc.
4.  **Validate:** Run `nvd diff /run/booted-system /run/current-system` after each module conversion to ensure no packages were accidentally dropped.