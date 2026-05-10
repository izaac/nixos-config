# Disable the gvfs WSD (Windows Service Discovery) backend at build time.
# The shipped wsdd.mount tries to spawn a `wsdd` Python daemon we don't
# install, producing recurring "No such file or directory" errors in the
# journal. This host has no Samba/SMB peers, so disabling the backend via
# its meson option silences the noise without affecting other gvfs backends.
_final: prev: {
  gvfs = prev.gvfs.overrideAttrs (oldAttrs: {
    mesonFlags = (oldAttrs.mesonFlags or []) ++ ["-Dwsdd=false"];
  });
}
