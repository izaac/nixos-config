{
  pkgs,
  userConfig,
  inputs,
  ...
}: {
  users.users.${userConfig.username} = {
    home = "/Users/${userConfig.username}";
    shell = pkgs.bashInteractive;
  };

  # Required by current nix-darwin for user-scoped options (Touch ID, etc.).
  system.primaryUser = userConfig.username;

  # Enable Touch ID for sudo (New syntax for nix-darwin)
  security.pam.services.sudo_local.touchIdAuth = true;

  # System profile holds only Mac-specific tools and the GNU userland that
  # replaces macOS's BSD utils. Shared CLI tooling (git, jq, eza, fzf, gcc,
  # kubectl, etc.) is installed once via home-manager, not duplicated here.
  environment.systemPackages = with pkgs; [
    ansifilter
    bashInteractive
    bottom
    broot
    cheat
    chezmoi
    coreutils
    curlie
    emacs
    findutils
    gawk
    indent
    gnused
    gnutar
    govc
    gnugrep
    lazygit
    lld
    mcfly
    pipenv
    shfmt
    terraform
    tmuxinator
    tree
    vim
    wimlib
    yamllint
    yarn
    yt-dlp
  ];

  # Nix daemon settings
  nix.package = pkgs.nix;
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["root" userConfig.username];
  };

  # Enable Bash at system level
  programs.bash.enable = true;
  programs.zsh.enable = false;

  environment.shells = [pkgs.bashInteractive];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # Used for backwards compatibility
  system.stateVersion = 5;

  # Use Home Manager
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "before-nix";
    extraSpecialArgs = {inherit inputs userConfig;};
    users.${userConfig.username} = {
      imports = [
        ../../home/core.nix
        inputs.stylix.homeModules.stylix
      ];
      home = {
        homeDirectory = pkgs.lib.mkForce "/Users/${userConfig.username}";
        stateVersion = "25.11";
      };
    };
  };
}
