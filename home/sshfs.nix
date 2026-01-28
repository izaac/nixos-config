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
      Description = "Mount Jellyfin SSHFS with Performance Optimizations";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "forking";
      ExecStart = ''
        ${pkgs.sshfs}/bin/sshfs ${userConfig.username}@${userConfig.sshHost}:/home/${userConfig.username} ${mountPoint} \
          -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 \
          -o StrictHostKeyChecking=no,UserKnownHostsFile=/dev/null \
          -o IdentityFile=${config.home.homeDirectory}/.ssh/id_ed25519_jellyfin \
          -o nodev,nosuid,allow_other,auto_unmount \
          -o cache=yes,kernel_cache,auto_cache,cache_timeout=3600 \
          -o entry_timeout=3600,attr_timeout=3600,negative_timeout=3600 \
          -o compression=no,Ciphers=aes128-gcm@openssh.com
      '';
      
      # Warm the cache in the background immediately after mounting
      ExecStartPost = "${pkgs.bash}/bin/bash -c '${pkgs.coreutils}/bin/ls -R ${mountPoint} > /dev/null 2>&1 &'";
      
      ExecStop = "fusermount -u ${mountPoint}";
      Restart = "on-failure";
      RestartSec = "10";
    };

    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}