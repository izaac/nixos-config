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
    ./hyprland.nix
    ./waybar.nix
    ./hyprlock.nix
    ./hypridle.nix
  ];

  home.username = userConfig.username;
  home.homeDirectory = "/home/${userConfig.username}";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  services.gnome-keyring = {
    enable = true;
    components = [ "pkcs11" "secrets" "ssh" ];
  };

  home.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";
  };

  services.ssh-agent.enable = false;

}
