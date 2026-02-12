{ config, pkgs, userConfig, ... }:

{
  imports = [
    ./shell.nix
    ./distrobox.nix
    ./desktop.nix
    ./firefox.nix
    ./gaming.nix
    ./dev.nix
    ./ssh.nix
    ./sshfs.nix
    ./tmux.nix
    ./kitty.nix
    ./cava.nix
    ./qt.nix
    ./chromium.nix
    ./lazyvim.nix
    ./plasma.nix
    ./fuzzel.nix
    ./cmus.nix
    ./dolphin-actions.nix
  ];

  home.username = userConfig.username;
  home.homeDirectory = "/home/${userConfig.username}";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    ventoy-full-qt
  ];

  services.ssh-agent.enable = true;
}
