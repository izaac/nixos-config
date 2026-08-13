# Pin stash-clipboard to nixos-unstable: it was merged after the 26.05 branch
# cut, so the stable channel has no such attribute. Note nixpkgs `stash` is
# stashapp, an unrelated media organizer; this one's binary is named `stash`.
#
# On top of that, build from upstream `main` rather than the v0.4.0 release.
# v0.4.0's `watch` ignores `--mime-type text/plain` and grabs whatever flavour
# the source offers first. Firefox offers `text/html` encoded as UTF-16LE, so
# every browser copy was stored as UTF-16 markup but labelled `text/plain`,
# and `--persist` then re-served those bytes to every consumer. Terminals stop
# at the NUL byte that follows the leading `<`, which is why pasting a Firefox
# selection produced a lone `<` or a wall of raw HTML. Upstream fixed this in
# `watch: capture plain text instead of UTF-16 HTML wrappers` plus
# `watch: prefer plain text over browser URI offers`, both unreleased.
# Drop this src/cargoDeps override once a tag after v0.4.0 lands in nixpkgs.
inputs: final: _prev: {
  stash-clipboard =
    inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}.stash-clipboard.overrideAttrs
    (old: rec {
      version = "0.4.0-unstable-2026-08-04";

      src = final.fetchFromGitHub {
        owner = "NotAShelf";
        repo = "stash";
        rev = "e8ee084e1bf6443f6bfe851f520c188609bf0e2e";
        hash = "sha256-WE8klna/g1bdXXqQ3pRxnRYUqfAznZWBp9Rd2czNlsk=";
      };

      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit src;
        hash = "sha256-xDCCMwgWU3WwJLwDkD++VmFmL12Kx0JZbcrVh9pg+r4=";
      };

      meta =
        (old.meta or {})
        // {
          priority = 10;
          changelog = "https://github.com/NotAShelf/stash/commits/main";
        };
    });
}
