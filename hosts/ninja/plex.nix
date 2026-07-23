{lib, ...}: {
  # Plex Media Server. The Sony Bravia runs the Plex app, so this serves the
  # local library to the TV (and any other Plex client) with native mkv
  # playback and audio/subtitle track selection. openFirewall opens the Plex
  # port (32400) plus its discovery ports.
  #
  # accelerationDevices defaults to ["*"], which disables systemd's
  # PrivateDevices and lets Plex reach the NVIDIA nodes for NVENC/NVDEC
  # transcoding (hardware transcoding is a Plex Pass feature). The device
  # nodes under /dev/nvidia* are world-rw, so no extra group is needed for
  # them.
  services.plex = {
    enable = true;
    openFirewall = true;
  };

  # On-demand only. Clearing wantedBy keeps Plex from starting at boot; it is
  # started manually with `plex-start` (systemctl start plex) when needed and
  # stopped with `plex-stop`.
  systemd.services.plex.wantedBy = lib.mkForce [];

  # Let wheel users start and stop plex.service through systemctl without a
  # sudo/polkit password prompt, so the `plex-start`/`plex-stop` aliases work
  # unprivileged.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "plex.service" &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  # NVENC hardware transcoding. Plex's bundled FFmpeg needs the NVIDIA
  # userspace libraries (libnvidia-encode, libnvcuvid, libcuda), which live in
  # /run/opengl-driver/lib. The Plex FHS wrapper only puts its own libs on
  # LD_LIBRARY_PATH, so inject the driver lib path here or transcoding falls
  # back to CPU. Enable "Use hardware acceleration when available" in the Plex
  # web UI to actually use it.
  systemd.services.plex.environment.LD_LIBRARY_PATH = "/run/opengl-driver/lib";

  # Plex runs as its own `plex` user. Add it to the `users` group so it can
  # read the shared media library that izaac fills.
  users.users.plex.extraGroups = ["users"];

  # Media library on the big data disk. Setgid (2775) so files and folders
  # dropped in keep the `users` group, keeping them readable by plex.
  systemd.tmpfiles.rules = [
    "d /mnt/data/media 2775 izaac users -"
  ];
}
