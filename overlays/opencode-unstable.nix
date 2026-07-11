# Pin opencode to nixos-unstable so the latest version tracks ahead of the
# nixos-26.05 stable release. Only this single package is taken from
# unstable; the rest of the system stays on the stable channel. The package
# is evaluated against unstable's own pkgs set so there is no stdenv mixing.
inputs: final: _prev: {
  opencode = inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}.opencode;
}
