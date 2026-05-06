# Pins copilot-cli to a known-good version.
# Check for updates: https://github.com/github/copilot-cli/releases
# To update: bump version + run `nix build` to get the new hash from the error.
_final: prev: {
  github-copilot-cli = prev.github-copilot-cli.overrideAttrs (_old: {
    version = "1.0.40";
    src = prev.fetchurl {
      url = "https://github.com/github/copilot-cli/releases/download/v1.0.40/copilot-linux-x64.tar.gz";
      hash = "sha256-ETlF92PA96vJX3oEBeQpxYV6oKhCK0EwAEiy35kGzPY=";
    };
  });
}
