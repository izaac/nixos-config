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

**Migration target**: nixpkgs PR #533450 backports 0.9.0 to release-26.05. Once merged and released,
drop this overlay.

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

Builds from upstream `main` (commit e8ee084) rather than v0.4.0 release because v0.4.0 has a bug:

- `watch` ignores `--mime-type text/plain`
- Firefox offers `text/html` encoded as UTF-16LE
- Every browser copy stored as UTF-16 markup but labelled `text/plain`
- Pasting produced lone `<` or raw HTML

Upstream fixed in `watch: capture plain text instead of UTF-16 HTML wrappers` +
`watch: prefer plain text over browser URI offers` (unreleased).

**Migration target**: Once a tag after v0.4.0 lands in nixpkgs, drop the `src/cargoDeps` override
and use stable.

**Affects**: All hosts (applied in lib/mkSystem.nix)

---

## Overlay Application

| Overlay               | Applied In             | Hosts             |
| --------------------- | ---------------------- | ----------------- |
| ashell-unstable.nix   | lib/mkSystem.nix       | ninja, windy      |
| opencode-unstable.nix | lib/common-nixpkgs.nix | ninja, windy, Mac |
| stash-unstable.nix    | lib/mkSystem.nix       | ninja, windy      |

---

## Decision Criteria for Adding Unstable Packages

Before adding a new unstable overlay, verify:

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
- [ ] Check if stash-clipboard >v0.4.0 in new stable
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

_Last reviewed: 2026-08-15_
