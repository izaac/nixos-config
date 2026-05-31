{
  pkgs,
  userConfig,
  inputs,
  ...
}: {
  users.users.${userConfig.username} = {
    home = "/Users/${userConfig.username}";
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = [
      # ninja
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKsLkTQ0VLpDXXQV3bLXouWWdBbhmkY01s2s6uvJYlBV izaac 2.0"
    ];
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
    python3
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

  # Silence the boot chime — no startup bong on power-on.
  system.startup.chime = false;

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

      # Snappier UI — strip window/focus animations and make resizes near-instant.
      NSAutomaticWindowAnimationsEnabled = false;
      NSWindowResizeTime = 0.001;
      NSUseAnimatedFocusRing = false;
      "com.apple.springing.delay" = 0.0; # no delay before folders spring open

      # Scroll direction matches Windows/Linux mouse convention — content
      # follows finger movement instead of macOS "natural" inversion.
      "com.apple.swipescrolldirection" = false;
      AppleShowScrollBars = "Always"; # persistent scrollbars, not auto-hide
      AppleMeasurementUnits = "Centimeters";
      AppleMetricUnits = 1;
      AppleTemperatureUnit = "Celsius";
      AppleICUForce24HourTime = true;
    };
    menuExtraClock = {
      Show24Hour = true;
      ShowDate = 1; # 0=when space allows, 1=always, 2=never
      ShowDayOfWeek = true;
      ShowSeconds = false;
    };
    spaces.spans-displays = false; # each monitor has its own Spaces (AeroSpace-friendly)
    finder = {
      AppleShowAllFiles = true; # show dotfiles
      ShowPathbar = true;
      ShowStatusBar = true;
      FXPreferredViewStyle = "Nlsv"; # list view
      _FXShowPosixPathInTitle = true;
      FXEnableExtensionChangeWarning = false;
      CreateDesktop = false; # hide desktop icons (AeroSpace tiling stays clean)
      FXDefaultSearchScope = "SCcf"; # search current folder by default, not whole Mac
      # NewWindowTarget = "Other" is required whenever NewWindowTargetPath is set;
      # "Home" alone would also work, but the explicit path survives a username change.
      NewWindowTarget = "Other";
      NewWindowTargetPath = "file:///Users/${userConfig.username}/";
    };
    dock = {
      autohide = true;
      autohide-delay = 0.0; # Dock appears the instant the cursor hits the edge
      autohide-time-modifier = 0.0; # no slide animation on show/hide
      launchanim = false; # no bouncing icon when launching apps
      expose-animation-duration = 0.1; # faster Mission Control transition
      minimize-to-application = true; # minimized windows fold into the app icon
      show-recents = false;
      mru-spaces = false; # don't auto-rearrange Spaces
      tilesize = 48;
      orientation = "bottom";
      mineffect = "scale"; # cheaper than the default genie warp
      # Hot corners: 1=disabled, 2=Mission Control, 3=App Windows, 4=Desktop,
      # 5=Start Screen Saver, 6=Disable Screen Saver, 10=Sleep Display,
      # 11=Launchpad, 12=Notification Center, 13=Lock Screen, 14=Quick Note.
      # All disabled — bumping a corner mid-aim should never trigger anything.
      wvous-tl-corner = 1;
      wvous-tr-corner = 1;
      wvous-bl-corner = 1;
      wvous-br-corner = 1;
    };
    screencapture = {
      location = "/Users/${userConfig.username}/Screenshots";
      type = "png";
      disable-shadow = true; # no drop-shadow border on window screenshots
    };
    trackpad = {
      Clicking = true; # tap to click
      TrackpadThreeFingerDrag = true;
    };
    loginwindow.GuestEnabled = false;

    # Universal Access — reduceTransparency / reduceMotion would help here,
    # but writing com.apple.universalaccess via `defaults` is TCC-gated:
    # darwin-rebuild fails unless the terminal running it has Full Disk
    # Access. Skipped to keep `just darwin-build` runnable without that
    # manual grant; toggle in System Settings → Accessibility → Display if
    # wanted (or grant FDA to kitty and re-enable here).

    # Disable App Nap for the Moonlight bundle: ensures macOS never throttles
    # the streaming client if the window briefly loses focus (e.g. Cmd-Tab to
    # check a chat). In fullscreen App Nap normally stays off anyway; this is
    # belt-and-suspenders for the windowed case.
    CustomUserPreferences = {
      "com.moonlight-stream.Moonlight" = {
        NSAppSleepDisabled = true;
      };
    };
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
    # SwipeAeroSpace lives in a third-party tap, not homebrew-cask core.
    taps = ["mediosz/tap"];
    casks = [
      "cyberduck"
      "docker-desktop"
      "firefox"
      "google-chrome"
      "gpg-suite-no-mail"
      # Hammerspoon: Lua automation; drives the Moonlight launch/quit watcher
      # in home/darwin/hammerspoon.nix (caffeinate + optional Focus toggle).
      "hammerspoon"
      "iterm2"
      "keka"
      "microsoft-edge"
      "moonlight"
      "plex"
      "plexamp"
      "protonvpn"
      "slack"
      "telegram"
      "timemachineeditor"
      "unetbootin"
      "visual-studio-code"
      "vlc"
      "windows-app"
      # 3-finger trackpad swipe to change AeroSpace workspaces (laptop niri feel).
      "mediosz/tap/swipeaerospace"
    ];
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
        ../../home/darwin/aerospace.nix
        ../../home/darwin/hammerspoon.nix
        ../../home/darwin/kitty.nix
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
