# Pin opencode to the izaac/nix-packages derivation so the CLI tracks
# upstream releases ahead of nixpkgs. Upstream ships standalone Bun
# binaries on its own update manifest; both stable and unstable channels
# lag. Falls back to nixpkgs-unstable while flake.lock still points at a
# nix-packages rev older than the package; the fallback is lazy and stops
# evaluating once the input carries opencode.
inputs: final: _prev: let
  system = final.stdenv.hostPlatform.system;
  izaacPackages = inputs.nix-packages.packages.${system} or {};
in {
  opencode =
    izaacPackages.opencode
    or inputs.nixpkgs-unstable.legacyPackages.${system}.opencode;
}
