# Take tailscale from nixos-unstable rather than the 26.05 release branch.
#
# The release branch only receives backports, so it sat on 1.98.10 while
# upstream shipped 1.102.3. Tailscale releases roughly fortnightly and the
# client is expected to track the coordination server, so falling several
# minor versions behind on a release branch is the normal outcome rather than
# a one-off.
#
# Safe to take from unstable: it is a single static Go binary with no kernel
# module, and modules/core/tailscale.nix uses only `services.tailscale`
# options, so nothing here depends on package internals. The package is
# evaluated against unstable's own pkgs set, so there is no stdenv mixing.
inputs: final: _prev: {
  tailscale = inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}.tailscale;
}
