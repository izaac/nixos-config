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

  # Enable Touch ID for sudo (New syntax for nix-darwin)
  security.pam.services.sudo_local.touchIdAuth = true;

  # List packages to install in system profile.
  environment.systemPackages = with pkgs; [
    ansifilter
    bashInteractive
    bottom
    broot
    cheat
    chezmoi
    coreutils
    curlie
    duf
    dust
    emacs
    eza
    fastfetch
    findutils
    fzf
    gawk
    gcc
    git
    delta
    indent
    gnused
    gnutar
    govc
    gping
    gnugrep
    kubernetes-helm
    jq
    k9s
    kubectl
    lazygit
    lld
    gnumake
    mcfly
    pipenv
    procs
    shellcheck
    shfmt
    terraform
    tmuxinator
    tree
    vim
    wimlib
    yamllint
    yarn
    yt-dlp
    zoxide
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
        inputs.stylix.homeManagerModules.stylix
      ];
      home = {
        homeDirectory = pkgs.lib.mkForce "/Users/${userConfig.username}";
        stateVersion = "25.11";
      };
    };
  };
}
