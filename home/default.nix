{ config, pkgs, userConfig, ... }:

{
  imports = [
    ./shell.nix
    ./desktop.nix
    ./firefox.nix
    ./gaming.nix
    ./dev.nix
    ./ssh.nix
    ./sshfs.nix
    ./tmux.nix
    ./kitty.nix
    ./cava.nix
  ];

  home.username = userConfig.username;
  home.homeDirectory = "/home/${userConfig.username}";
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;

}
