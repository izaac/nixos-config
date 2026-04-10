{userConfig, ...}: {
  imports = [
    ./shell.nix
    ./fastfetch.nix
    ./flatpak.nix
    ./ssh.nix
    ./rclone-gdrive.nix
    ./zellij.nix
    ./theme.nix
    ./whosthere.nix
    ./dev.nix
  ];

  home.username = userConfig.username;
  home.homeDirectory = "/home/${userConfig.username}";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
