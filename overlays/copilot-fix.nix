# Pins copilot-cli to a known-good version.
# Check for updates: https://github.com/github/copilot-cli/releases
# To update: bump version + run `nix build` to get the new hash from the error.
_final: prev: {
  github-copilot-cli = prev.github-copilot-cli.overrideAttrs (_old: {
    version = "1.0.21";
    src = prev.fetchurl {
      url = "https://github.com/github/copilot-cli/releases/download/v1.0.21/copilot-linux-x64.tar.gz";
      hash = "sha256-pvxJSj3Vp2JG+zNCS68Iq7W0y2iJ//KM8pUVXCixz3c=";
    };
  });
}
