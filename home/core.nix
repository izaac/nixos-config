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
    ./ai-agents
  ];

  home = {
    inherit (userConfig) username;
    homeDirectory = "/home/${userConfig.username}";
    stateVersion = "25.11";
  };

  programs.home-manager.enable = true;
}
