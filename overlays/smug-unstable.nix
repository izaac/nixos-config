# Take smug from nixos-unstable rather than the 26.05 release branch.
inputs: final: _prev: {
  smug = inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}.smug;
}
