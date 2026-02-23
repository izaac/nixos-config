{ config, pkgs, userConfig, ... }:

{
  imports = [
    ./shell.nix
    ./ssh.nix
    ./sshfs.nix
    ./rclone-gdrive.nix
    ./tmux.nix
    ./theme.nix
    ./whosthere.nix
    ./dev.nix
  ];

  home.username = userConfig.username;
  home.homeDirectory = "/home/${userConfig.username}";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;
}
