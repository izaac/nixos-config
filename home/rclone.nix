# rclone FUSE mounts as systemd user units. One helper, one unit per remote —
# shared mount flags and stop/exit handling stay in lockstep (a stop-path fix
# once landed in only one of two copy-pasted files).
#
# Note: user units cannot depend on network-online.target (system manager
# only); Restart/ExecStopPost per mount handle flaky-network starts instead.
{
  pkgs,
  config,
  lib,
  ...
}: let
  mkRcloneMount = {
    description,
    remote,
    mountPoint,
    service ? {},
  }: {
    Unit = {
      Description = description;
      After = ["graphical-session.target"];
    };

    Service =
      {
        Type = "exec";
        ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mountPoint}";
        # vfs-cache-mode full: essential for opening files (Office, PDF, etc)
        # directly from the mount; cache capped at 10G of local SSD.
        ExecStart = ''
          ${pkgs.rclone}/bin/rclone mount ${remote} ${mountPoint} \
            --vfs-cache-mode full \
            --vfs-cache-max-size 10G \
            --vfs-cache-max-age 24h \
            --dir-cache-time 72h \
            --vfs-read-chunk-size 32M \
            --vfs-read-chunk-size-limit 1G \
            --buffer-size 32M \
            --no-modtime
        '';
        # `-` prefix: ignore fusermount exit code. rclone unmounts itself on
        # SIGTERM before this runs, so fusermount usually returns
        # "Operation not permitted" because the mount is already gone.
        ExecStop = "-${pkgs.fuse}/bin/fusermount -uz ${mountPoint}";
        # Treat SIGTERM (143) as a clean exit so planned restarts (e.g.
        # home-manager activation) are not flagged as failures.
        SuccessExitStatus = "143";
      }
      // service;

    Install.WantedBy = ["default.target"];
  };
in {
  config = lib.mkIf pkgs.stdenv.isLinux {
    systemd.user.services = {
      rclone-gdrive = mkRcloneMount {
        description = "RClone Mount for Encrypted Google Drive (Zero-Knowledge)";
        remote = "gd-crypt:";
        mountPoint = "${config.home.homeDirectory}/PrivateGDrive";
        service = {
          Restart = "on-failure";
          RestartSec = "30";
        };
      };

      rclone-proton =
        mkRcloneMount {
          description = "RClone Mount for Proton Drive";
          remote = "proton:";
          mountPoint = "${config.home.homeDirectory}/ProtonDrive";
          service = {
            # NEVER auto-restart. Any failed restart re-hits /auth/v4/2fa with
            # the cached (stale) credential, and even 2-3 attempts can trip
            # Proton's account rate limiter (observed 2026-05-31). If the
            # mount dies, fire a desktop notification and stay dead — Chief
            # re-auths via `rclone config` (the `reconnect` subcommand is
            # OAuth-only and does not apply to the username/password/2FA
            # Proton backend), then `systemctl --user start rclone-proton`.
            Restart = "no";
            ExecStopPost = pkgs.writeShellScript "rclone-proton-notify-fail" ''
              if [ "$SERVICE_RESULT" != "success" ]; then
                ${pkgs.libnotify}/bin/notify-send -u critical \
                  "Proton Drive mount failed" \
                  "rclone-proton exited with $EXIT_STATUS. Re-auth: rclone config → edit proton → re-enter password + TOTP, then systemctl --user start rclone-proton"
              fi
            '';
          };
        }
        // {
          # Auto-start disabled: sits idle until started manually with
          # `systemctl --user start rclone-proton`. Avoids the rate-limiter
          # risk on session start when stale credentials are cached.
          Install.WantedBy = [];
        };
    };
  };
}
