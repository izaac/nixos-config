{ pkgs, config, lib, ... }:

let
  mountPoint = "${config.home.homeDirectory}/PrivateGDrive";
in
{
  systemd.user.services.rclone-gdrive = {
    Unit = {
      Description = "RClone Mount for Encrypted Google Drive (Zero-Knowledge)";
      After = [ "network-online.target" "graphical-session.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "simple";
      # Create the directory right before mounting
      ExecStartPre = "/run/current-system/sw/bin/mkdir -p ${mountPoint}";
      # Optimized for desktop usage:
      # - vfs-cache-mode full: Essential for opening files (Office, PDF, etc) directly from the mount
      # - vfs-cache-max-size: Limits local SSD usage to 10GB
      ExecStart = ''
        ${pkgs.rclone}/bin/rclone mount gd-crypt: ${mountPoint} \
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
      WantedBy = [ "default.target" ];
    };
  };
}
