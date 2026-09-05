# Pin ashell to a frozen nixpkgs rev: 26.05 ships 0.8.0, which predates the IPC
# socket, the notification daemon and the OSD, all of which are load-bearing
# here. Drop this once nixpkgs PR #533450 backports a new enough ashell to
# release-26.05.
#
# The source is `nixpkgs-ashell`, pinned by rev in flake.nix rather than the
# floating `nixpkgs-unstable`, because the network patch below breaks whenever
# upstream reworks the network service. Pinning keeps `just up` from failing on
# an ashell bump nobody asked for; bump the rev in flake.nix to move it.
#
# The patch fixes an upstream bug rather than a preference, so it is applied on
# every host: the network service retries a failed backend connection every five
# seconds for the lifetime of the session, with no backoff and no give-up. On a
# host without NetworkManager or iwd (ninja runs systemd-networkd) that is a
# permanent loop, roughly 17k pointless D-Bus round trips a day. The patch adds
# exponential backoff and stops after six failed attempts. Recheck it against
# src/services/network/mod.rs on every ashell bump.
#
# The second patch is a preference, but it has nowhere else to live: the
# brightness step is hardcoded at 5% and upstream exposes no setting for it, so
# it cannot be expressed in config the way volume_step can. Applied everywhere
# because it is inert on a host with no backlight.
inputs: final: _prev: {
  ashell = inputs.nixpkgs-ashell.legacyPackages.${final.stdenv.hostPlatform.system}.ashell
    .overrideAttrs (old: {
    patches =
      (old.patches or [])
      ++ [
        ./patches/ashell-network-backoff.patch
        ./patches/ashell-brightness-step.patch
      ];
  });
}
