{ config, pkgs, userConfig, ... }:

{
  # Enable user access to FUSE mounts (required for allow_other with SSHFS)
  programs.fuse.userAllowOther = true;

  # On-demand SSHFS mount for Jellyfin
  # Using system-level fileSystems because systemd user-level automounts 
  # lack permissions for autofs.
  fileSystems."/home/${userConfig.username}/Jellyfin" = {
    device = "${userConfig.username}@${userConfig.sshHost}:/home/${userConfig.username}";
    fsType = "fuse.sshfs";
    options = [
      "noauto"
      "x-systemd.automount"
      "allow_other"
      "user"
      "IdentityFile=/home/${userConfig.username}/.ssh/id_ed25519"
      "reconnect"
      "ServerAliveInterval=15"
      "StrictHostKeyChecking=no"
      "UserKnownHostsFile=/dev/null"
      "nodev"
      "nosuid"
      "_netdev"
      "x-systemd.idle-timeout=600" # Unmount after 10 minutes of inactivity
      "x-systemd.mount-timeout=10"
    ];
  };
}
