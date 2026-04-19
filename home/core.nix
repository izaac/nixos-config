{ userConfig, ... }: {
  imports = [
    ./shell.nix
    ./fastfetch.nix
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
    stateVersion = "25.11";
  };

  programs.home-manager.enable = true;
}
