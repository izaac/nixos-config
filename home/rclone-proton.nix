{
  pkgs,
  config,
  lib,
  ...
}: let
  mountPoint = "${config.home.homeDirectory}/ProtonDrive";
in {
  config = lib.mkIf pkgs.stdenv.isLinux {
    systemd.user.services.rclone-proton = {
      Unit = {
        Description = "RClone Mount for Proton Drive";
        After = ["network-online.target" "graphical-session.target"];
        Wants = ["network-online.target"];
      };

      Service = {
        Type = "exec";
        ExecStartPre = "/run/current-system/sw/bin/mkdir -p ${mountPoint}";
        # Proton Drive API is stricter than GDrive on rate limits, so
        # cache aggressively and avoid extra metadata round-trips.
        ExecStart = ''
          ${pkgs.rclone}/bin/rclone mount proton: ${mountPoint} \
            --vfs-cache-mode full \
            --vfs-cache-max-size 10G \
            --vfs-cache-max-age 24h \
            --dir-cache-time 72h \
            --vfs-read-chunk-size 32M \
            --vfs-read-chunk-size-limit 1G \
            --buffer-size 32M \
            --no-modtime
        '';
        ExecStop = "${pkgs.fuse}/bin/fusermount -uz ${mountPoint}";
        # NEVER auto-restart. Any failed restart re-hits /auth/v4/2fa with
        # the cached (stale) credential, and even 2-3 attempts can trip
        # Proton's account rate limiter (observed 2026-05-31). If the
        # mount dies, fire a desktop notification and stay dead — Chief
        # re-auths with `rclone config reconnect proton:` then
        # `systemctl --user start rclone-proton`.
        Restart = "no";
        ExecStopPost = pkgs.writeShellScript "rclone-proton-notify-fail" ''
          if [ "$SERVICE_RESULT" != "success" ]; then
            ${pkgs.libnotify}/bin/notify-send -u critical \
              "Proton Drive mount failed" \
              "rclone-proton exited with $EXIT_STATUS. Run: rclone config reconnect proton: && systemctl --user start rclone-proton"
          fi
        '';
      };

      Install = {
        WantedBy = ["default.target"];
      };
    };
  };
}
