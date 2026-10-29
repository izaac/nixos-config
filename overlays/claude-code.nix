# Pin claude-code to izaac/nix-packages if available, falling back to
# nixpkgs-unstable so the CLI tracks newer releases ahead of the stable channel.
inputs: final: _prev: let
  system = final.stdenv.hostPlatform.system;
  izaacPackages = inputs.nix-packages.packages.${system} or {};
  unstablePkgs = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };
in {
  claude-code =
    izaacPackages.claude-code
    or unstablePkgs.claude-code;
}
