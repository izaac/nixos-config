{ pkgs, config, userConfig, lib, ... }:

let
  mountPoint = "${config.home.homeDirectory}/Jellyfin";
  # Escaped path for the unit name: /home/username/Jellyfin -> home-username-Jellyfin
  unitName = lib.replaceStrings ["/"] ["-"] (lib.removePrefix "/" mountPoint);
in
{
  systemd.user.mounts."${unitName}" = {
    Unit = {
      Description = "Mount Jellyfin SSHFS";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Mount = {
      What = "${userConfig.username}@${userConfig.sshHost}:/home/${userConfig.username}";
      Where = mountPoint;
      Type = "fuse.sshfs";
      Options = "reconnect,ServerAliveInterval=15,StrictHostKeyChecking=no,UserKnownHostsFile=/dev/null,IdentityFile=${config.home.homeDirectory}/.ssh/id_ed25519_jellyfin,nodev,nosuid,_netdev,allow_other";
    };
  };

  systemd.user.automounts."${unitName}" = {
    Unit = {
      Description = "Automount Jellyfin SSHFS";
      # Start after graphical session to avoid any potential impact on login speed
      After = [ "graphical-session.target" ];
    };
    Automount = {
      Where = mountPoint;
      TimeoutIdleSec = 600;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
