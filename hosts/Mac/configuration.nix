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

  # Local Linux build VM (via Apple Virtualization). Lets this arm64 Mac build
  # Linux closures without a remote builder; it registers itself in
  # nix.buildMachines automatically. binfmt adds QEMU user-mode emulation so it
  # can also build x86_64-linux (for ninja / windy) — correct but slow, and the
  # VM disk grows with x86_64 store paths as they are built.
  nix.linux-builder = {
    enable = true;
    maxJobs = 4;
    # binfmt teaches the guest VM to *run* x86_64 via QEMU; systems advertises
    # x86_64-linux in /etc/nix/machines so the Mac's nix actually offloads
    # those builds to it (binfmt alone is necessary but not sufficient).
    systems = ["aarch64-linux" "x86_64-linux"];
    config.boot.binfmt.emulatedSystems = ["x86_64-linux"];
  };

  # Enable Bash at system level
  programs.bash.enable = true;
  programs.zsh.enable = false;

  environment.shells = [pkgs.bashInteractive];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # Tailscale client daemon (managed via launchd). Installs the CLI and starts
  # tailscaled; run `sudo tailscale up` once to join the tailnet, after which
  # this Mac can reach ninja over Tailscale SSH.
  services.tailscale.enable = true;

  # Declarative macOS preferences. Only the keys listed here are managed;
  # every other System Settings value is left as-is. This writes `defaults`,
  # it never touches application data — Tunnelblick et al. are unaffected.
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark"; # match the Catppuccin-dark theme on the other hosts
      AppleShowAllExtensions = true;
      ApplePressAndHoldEnabled = false; # hold key = repeat, not the accent popup
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSNavPanelExpandedStateForSaveMode = true; # expanded save dialogs by default
    };
    finder = {
      AppleShowAllFiles = true; # show dotfiles
      ShowPathbar = true;
      ShowStatusBar = true;
      FXPreferredViewStyle = "Nlsv"; # list view
      _FXShowPosixPathInTitle = true;
      FXEnableExtensionChangeWarning = false;
    };
    dock = {
      autohide = true;
      show-recents = false;
      mru-spaces = false; # don't auto-rearrange Spaces
      tilesize = 48;
    };
    screencapture = {
      location = "/Users/${userConfig.username}/Screenshots";
      type = "png";
    };
    trackpad = {
      Clicking = true; # tap to click
      TrackpadThreeFingerDrag = true;
    };
    loginwindow.GuestEnabled = false;
  };

  # macOS Application Firewall — governs INBOUND connections only.
  # blockAllIncoming = false keeps Remote Login (SSH) reachable, and outbound
  # VPN tunnels (Tunnelblick/OpenVPN) are unaffected. Stealth mode stays off so
  # it does not drop the ICMP/diagnostic traffic VPN tooling relies on.
  networking.applicationFirewall = {
    enable = true;
    allowSigned = true;
    allowSignedApp = true;
    blockAllIncoming = false;
    enableStealthMode = false;
  };

  # Homebrew manages GUI apps/casks that nixpkgs can't ship on Darwin. The
  # nix-darwin module only *drives* an existing brew install (run the official
  # installer once first). cleanup = "none" means it NEVER removes anything not
  # listed here, so manually-installed apps stay put. Add casks/masApps to taste.
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };
    casks = [];
    brews = [];
    masApps = {};
  };

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
