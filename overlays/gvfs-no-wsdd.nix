# Drop the WSD (Windows Service Discovery) backend from gvfs. The shipped
# wsdd.mount tries to spawn a `wsdd` Python daemon that we don't install,
# producing recurring "No such file or directory" errors in the journal.
# This host has no Samba/SMB peers, so removing the mount file silences the
# noise without affecting other gvfs backends.
_final: prev: {
  gvfs = prev.gvfs.overrideAttrs (oldAttrs: {
    postInstall =
      (oldAttrs.postInstall or "")
      + ''
        rm -f $out/share/gvfs/mounts/wsdd.mount
      '';
  });
}
