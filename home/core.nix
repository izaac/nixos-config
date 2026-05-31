{userConfig, ...}: {
  imports = [
    ./shell.nix
    ./fastfetch.nix
    ./ssh.nix
    ./rclone-gdrive.nix
    ./rclone-proton.nix
    ./tmux.nix
    ./theme.nix
    ./whosthere.nix
    ./dev.nix
    ./ai-agents
  ];

  home = {
    inherit (userConfig) username;
    stateVersion = "25.11";
    # Tracking nixos-unstable; HM master may sit on a newer release label.
    enableNixpkgsReleaseCheck = false;
  };

  programs.home-manager.enable = true;
}
