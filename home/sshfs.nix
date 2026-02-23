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
      Description = "Mount Jellyfin SSHFS (Delayed to avoid login freeze)";
      After = [ "network-online.target" "graphical-session.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "forking";
      # Wait 10 seconds after the session starts to avoid blocking login UI
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";
      
      # Use bash wrapper to read the secret host at runtime
      ExecStart = pkgs.writeShellScript "mount-jellyfin-sshfs" ''
        HOST=$(cat /run/secrets/sshHost)
        ${pkgs.sshfs}/bin/sshfs ${userConfig.username}@$HOST:/home/${userConfig.username} ${mountPoint} \
          -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 \
          -o StrictHostKeyChecking=no,UserKnownHostsFile=/dev/null \
          -o IdentityFile=${config.home.homeDirectory}/.ssh/id_ed25519_jellyfin \
          -o nodev,nosuid,allow_other,auto_unmount,idmap=user \
          -o kernel_cache,auto_cache \
          -o entry_timeout=3600,attr_timeout=3600,negative_timeout=3600 \
          -o dir_cache=yes,dcache_timeout=3600 \
          -o compression=no,Ciphers=aes128-gcm@openssh.com \
          -o max_conns=4
      '';
      
      ExecStop = "/run/current-system/sw/bin/fusermount -uz ${mountPoint}";
      TimeoutStopSec = 5;
      Restart = "on-failure";
      RestartSec = "10";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
