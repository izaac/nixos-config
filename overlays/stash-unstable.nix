# Pin stash-clipboard to nixos-unstable: it was merged after the 26.05 branch
# cut, so the stable channel has no such attribute. Note nixpkgs `stash` is
# stashapp, an unrelated media organizer; this one's binary is named `stash`.
inputs: final: _prev: {
  stash-clipboard =
    inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}.stash-clipboard.overrideAttrs
    (old: {
      meta = (old.meta or {}) // {priority = 10;};
    });
}
