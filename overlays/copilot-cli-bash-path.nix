# The Copilot CLI hard-codes `/bin/bash` when it spawns the pty backing its
# shell tool. NixOS only ships `/bin/sh`, so every shell invocation from the
# agent fails with "Failed to start bash process". The nixpkgs derivation puts
# bash on the wrapper's PATH, but that does not help because the path is
# absolute.
#
# Rewrite the two bundled JavaScript files that contain the literal so they
# point at bash from nixpkgs. `--replace-fail` makes the build break loudly if
# a future release drops or renames the literal, rather than silently shipping
# a broken shell tool again.
final: prev: {
  github-copilot-cli = prev.github-copilot-cli.overrideAttrs (oldAttrs: {
    postInstall =
      (oldAttrs.postInstall or "")
      + ''
        substituteInPlace \
          "$out"/lib/github-copilot-cli/app.js \
          "$out"/lib/github-copilot-cli/sdk/index.js \
          --replace-fail '"/bin/bash"' '"${final.bashInteractive}/bin/bash"'
      '';
  });
}
