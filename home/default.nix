{ config, pkgs, ... }:

{
  imports = [
    ./shell.nix
    ./desktop.nix
    ./gaming.nix
    ./dev.nix # Put your vim/vscode stuff here
  ];

  home.username = "izaac";
  home.homeDirectory = "/home/izaac";
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
