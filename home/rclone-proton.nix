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
        Restart = "on-failure";
        RestartSec = "10";
      };

      Install = {
        WantedBy = ["default.target"];
      };
    };
  };
}
