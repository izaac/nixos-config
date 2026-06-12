{userConfig, ...}: {
  imports = [
    ./shell.nix
    ./fastfetch.nix
    ./ssh.nix
    ./rclone.nix
    ./tmux.nix
    ./theme.nix
    ./whosthere.nix
    ./dev.nix
    ./ai-agents
  ];

  home = {
    inherit (userConfig) username;
    stateVersion = "25.11";
  };

  # Manage the XDG base directories and export XDG_*_HOME so the userDirs,
  # mimeApps and configFile entries declared elsewhere are fully compliant.
  xdg.enable = true;

  programs.home-manager.enable = true;
}
