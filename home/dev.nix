{
  pkgs,
  userConfig,
  ...
}: {
  home = {
    packages = with pkgs; [
      # --- CORE DEPENDENCIES ---
      gcc
      gnumake
      tree-sitter

      # --- LANGUAGES & TOOLCHAINS ---
      docker-compose
      nodejs

      # --- DATA & FORMATTING ---
      sqlite

      # --- LSPs & LINTERS ---
      bash-language-server
      shellcheck
      luajitPackages.lua-lsp
      nil

      # --- UTILS ---
    ];

    file = {
      ".gnupg/common.conf".text = "use-keyboxd";
      ".pam-gnupg".text = ''
        558F90AD0CFA39DB14CF2E9370073BF860AE0A2A
        9FE9496B3FF98EED829F2FD4BE0A07C5C64AA998
        841969EBFACD2E9E45FF7349BE991D37D7079FBF
      '';

      # Devshell stdenv prepends GNU coreutils to PATH, burying user
      # profile tools (uutils-coreutils, rm-improved, etc.).
      # Wraps use_flake to re-prepend user profile after devshell PATH.
      ".config/direnv/lib/zz-user-path.sh".text = ''
        eval "_original_$(declare -f use_flake)"
        use_flake() {
          _original_use_flake "$@"
          local ret=$?
          PATH_add ${if pkgs.stdenv.isDarwin then "/run/current-system/sw/bin" else "/etc/profiles/per-user/$USER/bin"}
          return $ret
        }
      '';
    };
  };

  # --- GIT CONFIGURATION (25.11 FIXED) ---
  programs = {
    git = {
      enable = true;
      package = pkgs.git;
      lfs.enable = true;

      # Signing remains a top-level attribute in Home Manager for now
      signing = {
        key = userConfig.gitKey;
        signByDefault = true;
      };

      # Everything else moves into 'settings'
      settings = {
        user = {
          inherit (userConfig) name;
          inherit (userConfig) email;
        };

        init.defaultBranch = "main";
        credential.helper = if pkgs.stdenv.isDarwin then "osxkeychain" else "libsecret";
        safe.directory = userConfig.dotfilesDir;

        # Note the singular 'alias' key under settings
        alias = {
          quickserve = "daemon --verbose --export-all --base-path=.git --reuseaddr --strict-paths .git/";
          logline = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
          wip = "commit -am 'WIP'";
          rlast = "reset --hard HEAD~1";
          incoming = "log HEAD..origin/main --oneline";
          outgoing = "log origin/main..HEAD --oneline";
          unstage = "reset HEAD --";
        };
      };
    };

    # --- DELTA (Diff Tool) ---
    delta = {
      enable = true;
      package = pkgs.delta;
      enableGitIntegration = true;
      options = {
        navigate = true;
        side-by-side = true;
        line-numbers = true;
      };
    };

    # --- GITUI ---
    gitui.enable = true;

    # --- GPG ---
    gpg = {
      enable = true;
      package = pkgs.gnupg;
      mutableKeys = true;
      mutableTrust = true;
    };

    # --- DIRENV ---
    direnv = {
      enable = true;
      package = pkgs.direnv;
      nix-direnv.enable = true;
      # TOML configuration to surgically silence the export list.
      config = {
        global = {
          hide_env_diff = true;
        };
      };
    };
  };

  services.gpg-agent = {
    enable = true;
    enableSshSupport = false;
    pinentry.package = if pkgs.stdenv.isDarwin then pkgs.pinentry_mac else pkgs.pinentry-gnome3;
    defaultCacheTtl = 3600;
    extraConfig = ''
      allow-preset-passphrase
    '';
  };
}
