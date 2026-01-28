{ pkgs, config, userConfig, lib, ... }:

let
  mountPoint = "${config.home.homeDirectory}/Jellyfin";
in
{
  # Ensure the mount point exists
  home.activation.createJellyfinMountPoint = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p ${mountPoint}
  '';

  systemd.user.services.jellyfin-mount = {
    Unit = {
      Description = "Mount Jellyfin SSHFS";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "forking";
      # -f runs in foreground, but forking type with sshfs (which forks by default) is often more reliable in systemd
      ExecStart = "${pkgs.sshfs}/bin/sshfs ${userConfig.username}@${userConfig.sshHost}:/home/${userConfig.username} ${mountPoint} -o reconnect,ServerAliveInterval=15,StrictHostKeyChecking=no,UserKnownHostsFile=/dev/null,IdentityFile=${config.home.homeDirectory}/.ssh/id_ed25519_jellyfin,nodev,nosuid,allow_other";
      ExecStop = "fusermount -u ${mountPoint}";
      Restart = "on-failure";
      RestartSec = "10";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}