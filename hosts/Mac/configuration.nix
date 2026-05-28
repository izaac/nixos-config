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

  # Enable Touch ID for sudo (New syntax for nix-darwin).
  # reattach loads pam_reattach so Touch ID also works inside tmux/screen.
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

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
    nh
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

  # nix-darwin has no programs.nh module, so install the CLI directly and let
  # the daemon handle scheduled GC + dedup (nh clean is then run by hand).
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };
  nix.optimise.automatic = true;

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
      # stylix.enable is off on this host, so the Darwin module never injects
      # the useGlobalPkgs override that disables the overlay. Without
      # stylix.enable the HM module still defaults overlays.enable to true and
      # sets nixpkgs.overlays, which useGlobalPkgs ignores and warns about.
      # Disable it explicitly (matches stylix's own useGlobalPkgs handling).
      stylix.overlays.enable = false;
      home = {
        homeDirectory = pkgs.lib.mkForce "/Users/${userConfig.username}";
        stateVersion = "25.11";
      };
    };
  };
}
