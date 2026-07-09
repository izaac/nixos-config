# nixpkgs settings shared by every host (NixOS and Darwin). Platform-specific
# overlays are appended by lib/mkSystem.nix; nixpkgs.overlays merges across
# modules.
inputs: {
  nixpkgs = {
    config.allowUnfree = true;
    overlays = [
      (import ../overlays/ai-trace-scanner.nix inputs)
      (import ../overlays/opencode-unstable.nix inputs)
    ];
  };
}
