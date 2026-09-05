# nixpkgs-unstable Usage Reference

This document tracks which packages are pulled from `nixpkgs-unstable` instead of the stable
`nixos-26.05` channel, and why. The goal is to minimize unstable usage and migrate back to stable
when possible.

---

## Current Overlays Using Unstable

### 1. ashell (ashell-unstable.nix)

**Package**: `ashell` **Reason**: Stable 26.05 ships ashell 0.8.0, which lacks:

- IPC socket
- Notification daemon
- OSD (on-screen display)

These are load-bearing features for this config. The overlay also applies two patches:

- `ashell-network-backoff.patch`: Fixes exponential backoff for network service retries (prevents
  17k pointless D-Bus round trips/day on hosts without NetworkManager/iwd)
- `ashell-brightness-step.patch`: Configurable brightness step (upstream hardcodes 5%)

Both patches were rechecked against ashell 0.10.0 and are still required: upstream keeps the flat
five second retry with no give-up, and still hardcodes the brightness step at 5% with no setting to
override it. The backoff patch had to be refreshed at 0.10.0, which added a third field to
`State::Active` and broke the first hunk's context. Expect the same on future bumps, since every
hunk of that patch touches the network service's state machine.

**Migration target**: nixpkgs PR #533450 backports 0.9.0 to release-26.05, still open. Once merged
and released, drop this overlay.

**Pinning**: ashell comes from a dedicated `nixpkgs-ashell` input in `flake.nix`, locked to an
explicit rev (`801bef6a`, ashell 0.10.0) rather than the floating `nixpkgs-unstable`.
`nix flake update` cannot move an input whose URL names a rev, so a routine `just up` can no longer
bump ashell and break the network patch. To bump ashell deliberately: change that rev, rebuild, and
refresh the patch if it stops applying.

**Affects**: All hosts (applied in lib/mkSystem.nix)

---

### 2. opencode (opencode-unstable.nix)

**Package**: `opencode` **Reason**: Track latest version ahead of nixos-26.05 stable release. Only
this single package from unstable; rest of system stays on stable channel.

**Migration target**: When nixos-26.05 gets opencode update, or when nixos-27.05 is released.
Re-evaluate at each channel bump.

**Affects**: All hosts (applied in lib/common-nixpkgs.nix)

---

### 3. stash-clipboard (stash-unstable.nix)

**Package**: `stash-clipboard` **Reason**: Package was merged after 26.05 branch cut; stable channel
has no such attribute (nixpkgs `stash` is stashapp, an unrelated media organizer).

Pins to `nixpkgs-unstable` which ships `v0.5.0` (including upstream fixes for plain text offers and
MIME types).

**Migration target**: Once `stash-clipboard` lands in nixpkgs stable, drop the overlay.

**Affects**: Linux hosts (applied in `lib/mkSystem.nix`)

---

## Overlay Application

| Overlay               | Applied In             | Hosts             | Source                        |
| --------------------- | ---------------------- | ----------------- | ----------------------------- |
| ashell-unstable.nix   | lib/mkSystem.nix       | ninja, windy      | `nixpkgs-ashell` (pinned rev) |
| opencode-unstable.nix | lib/common-nixpkgs.nix | ninja, windy, Mac | `nixpkgs-unstable` (floating) |
| stash-unstable.nix    | lib/mkSystem.nix       | ninja, windy      | `nixpkgs-unstable` (floating) |

---

## What NOT to Put in Overlays

Do **NOT** add overlays for:

1. Packages available in stable with acceptable versions
2. System packages that affect large dependency graphs without justification
3. Complex packages that might cause build failures or mass rebuilds

---

## Checklist for Adding an Unstable Package

Before adding a new overlay, ensure:

1. **Not in stable**: Package genuinely missing from `nixos-26.05`
2. **No alternative**: Cannot use `nixpkgs-unstable` package via `nix-shell`, `nix run`, or
   home-manager overlay
3. **Documented**: Reason, migration target, and affected hosts recorded here
4. **Minimal scope**: Only the specific package, not entire subsystems
5. **Re-evaluation date**: Set a reminder to check at next channel bump

---

## Re-evaluation Checklist (per channel bump)

- [ ] Check if ashell 0.9.0+ is in new stable
- [ ] Check if opencode updated in new stable
- [ ] Check if stash-clipboard is in new stable
- [ ] Remove overlays that are no longer needed
- [ ] Update this document

---

## Pinning Strategy

Currently `nixpkgs-unstable` tracks the `nixos-unstable` branch (floating). For reproducibility,
consider pinning to a specific commit:

```nix
nixpkgs-unstable.url = "github:nixos/nixpkgs/<commit-hash>";
```

Update the commit hash when re-evaluating. This prevents unexpected breakage from upstream changes.

---

_Last reviewed: 2026-09-05_
