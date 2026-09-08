# `podman machine` on this Mac uses the libkrun provider, which shells out to a
# `krunkit` binary found on PATH. Homebrew's podman formula ships gvproxy and
# vfkit but not krunkit, so `podman machine start` fails with
# "exec: krunkit: executable file not found in $PATH" unless something else
# provides it.
#
# Stable 26.05 has krunkit 1.2.1, which boots the VM but leaves the rootful
# podman API socket dead: `podman info` then fails with "ssh: rejected: connect
# failed" and only the rootless sockets under /run/user exist. Measured by
# starting the same machine with each binary in turn; 1.3.2 from unstable comes
# up with /run/podman/podman.sock present.
#
# Migration target: drop this overlay once krunkit >= 1.3.2 reaches stable.
inputs: final: _prev: {
  krunkit = inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}.krunkit;
}
