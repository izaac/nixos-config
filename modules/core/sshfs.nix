{ config, pkgs, userConfig, ... }:

{
  # Enable user access to FUSE mounts (required for allow_other with SSHFS)
  programs.fuse.userAllowOther = true;
}