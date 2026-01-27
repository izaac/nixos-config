{ config, pkgs, ... }:

{
  imports = [
    ./shell.nix
    ./desktop.nix
    ./gaming.nix
    ./dev.nix
    ./ssh.nix
    ./tmux.nix
    ./kitty.nix
    ./cava.nix
  ];

  home.username = "izaac";
  home.homeDirectory = "/home/izaac";
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
