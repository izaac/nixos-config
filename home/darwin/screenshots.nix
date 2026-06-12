# system.defaults.screencapture.location points at ~/Screenshots, but macOS
# silently falls back to the desktop if the directory does not exist. Make
# sure it does.
{lib, ...}: {
  home.activation.ensureScreenshotsDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$HOME/Screenshots"
  '';
}
