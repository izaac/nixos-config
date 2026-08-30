# Pin stash-clipboard to nixos-unstable: it was merged after the 26.05 branch
# cut, so the stable channel has no such attribute. Note nixpkgs `stash` is
# stashapp, an unrelated media organizer; this one's binary is named `stash`.
# Lower priority (10) so wl-clipboard provides wl-copy/wl-paste without collision.
# Drop this overlay once nixpkgs stable includes stash-clipboard.
inputs: final: _prev: {
  stash-clipboard =
    final.lib.setPrio 10
    inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}.stash-clipboard;
}
