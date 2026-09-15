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
    cacheDir ? null,
    rcPort ? null,
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
        ExecStart = let
          flags =
            [
              "--vfs-cache-mode full"
              "--vfs-cache-max-size 10G"
              "--vfs-cache-max-age 24h"
              "--dir-cache-time 72h"
              "--vfs-read-chunk-size 32M"
              "--vfs-read-chunk-size-limit 1G"
              "--buffer-size 32M"
              "--no-modtime"
            ]
            ++ lib.optional (cacheDir != null) "--cache-dir ${cacheDir}"
            ++ lib.optionals (rcPort != null) [
              "--rc"
              "--rc-addr 127.0.0.1:${toString rcPort}"
              "--rc-no-auth"
            ];
        in "${lib.getExe pkgs.rclone} mount ${remote} ${mountPoint} ${lib.concatStringsSep " " flags}";
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

  # Shared by the mount unit and by ulc, so the two cannot drift apart.
  ulCrypt = {
    unit = "rclone-ul-crypt";
    remote = "ul-crypt:";
    mountPoint = "/mnt/data/ul";
    # Media files are large and the VFS cache holds whole files, so the cache
    # goes next to the mount on /mnt/data rather than filling the encrypted
    # root's default ~/.cache/rclone.
    cacheDir = "/mnt/data/ul-cache";
    rcPort = 5573;
  };
in {
  config = lib.mkIf pkgs.stdenv.isLinux {
    home.packages = let
      inherit (ulCrypt) unit mountPoint remote cacheDir rcPort;

      ulc = pkgs.writeShellApplication {
        name = "ulc";
        # mountpoint comes from util-linux, and the script also filters rclone
        # output through grep and sed. writeShellApplication appends to $PATH
        # rather than replacing it, so anything missing here resolves from the
        # caller's environment or not at all.
        runtimeInputs = with pkgs; [rclone systemd coreutils util-linux gnugrep gnused];
        # runtimeEnv goes through lib.toShellVar, so the values are quoted
        # properly rather than interpolated into the source as bare words.
        runtimeEnv = {
          REMOTE = remote;
          MOUNT = mountPoint;
          CACHE = cacheDir;
          UNIT = unit;
          RC_ADDR = "127.0.0.1:${toString rcPort}";
        };
        # The body lives in ulc.sh so that it is formatted by treefmt and
        # checked by an editor as ordinary shell. readFile inserts it verbatim,
        # so the script's own expansions are never seen by Nix.
        text = builtins.readFile ./ulc.sh;
      };
    in [
      ulc

      # Kept as their own commands because they are the two actions used
      # without thinking about the rest of the interface.
      (pkgs.writeShellScriptBin "ul-mount" ''exec ${lib.getExe ulc} mount "$@"'')
      (pkgs.writeShellScriptBin "ul-umount" ''exec ${lib.getExe ulc} umount "$@"'')
    ];

    systemd.user.services = {
      rclone-ul-crypt =
        mkRcloneMount {
          description = "RClone Mount for Ulozto (encrypted)";
          inherit (ulCrypt) remote mountPoint cacheDir;
          # dir-cache-time is 72h and the backend cannot report changes, so an
          # upload made straight to the remote would stay invisible in the
          # mount for three days. The control socket lets `ulc` invalidate the
          # affected directory right after a transfer. Loopback only, and the
          # firewall does not open the port.
          inherit (ulCrypt) rcPort;
        }
        // {
          # On demand only, via ul-mount.
          Install.WantedBy = [];
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
