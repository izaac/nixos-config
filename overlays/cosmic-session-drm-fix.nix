# Fixes DRM master race condition in COSMIC session handoff.
#
# When greetd hands off from the greeter to the user session on the same VT,
# logind doesn't detect a VT change (VT1 → VT1 is a no-op), so it never
# activates the new session. Without an active session, cosmic-comp can't
# acquire DRM master and falls back to broken "unprivileged mode".
#
# Fix: call `loginctl activate` before starting the compositor to explicitly
# activate the session, bypassing the VT-change dependency.
final: prev: {
  cosmic-session = prev.cosmic-session.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [final.makeWrapper];
    postInstall =
      (old.postInstall or "")
      + ''
        wrapProgram $out/bin/start-cosmic \
          --run '${final.systemd}/bin/loginctl activate "$XDG_SESSION_ID" 2>/dev/null || true'
      '';
  });
}
