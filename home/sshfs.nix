{ pkgs, config, userConfig, ... }:

{
  systemd.user.services.mount-jellyfin = {
    Unit = {
      Description = "Mount Jellyfin SSHFS";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      # Ensure the mount point exists
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/Jellyfin";
      
      # Mount using sshfs in foreground mode (-f) so systemd can track it
      ExecStart = ''
        ${pkgs.sshfs}/bin/sshfs ${userConfig.username}@${userConfig.sshHost}:/home/${userConfig.username} %h/Jellyfin \
          -f \
          -o reconnect \
          -o ServerAliveInterval=15 \
          -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          -o IdentityFile=%h/.ssh/id_ed25519
      '';
      
      # Clean up on stop
      ExecStop = "${pkgs.fuse}/bin/fusermount -u %h/Jellyfin";
      
      Restart = "always";
      RestartSec = "10s";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}

