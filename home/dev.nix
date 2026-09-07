{
  lib,
  pkgs,
  userConfig,
  ...
}: let
  # gpg-agent runs as a systemd user service that inherits the graphical
  # session environment, so WAYLAND_DISPLAY is always set from its point of
  # view. A pinentry chosen from that environment therefore always opens a
  # GUI dialog, even when the caller is a tmux pane on a different workspace,
  # where the dialog goes unnoticed and eventually times out.
  #
  # gpg forwards PINENTRY_USER_DATA from the calling process to the agent,
  # which re-exports it for pinentry, so the caller is the only reliable
  # source of truth. home/shell/gpg-tty.sh sets it for every interactive
  # shell; callers that leave it unset have no terminal to draw on either,
  # so the GUI dialog is the correct default.
  pinentry-auto = pkgs.writeShellScriptBin "pinentry" ''
    case "''${PINENTRY_USER_DATA:-}" in
      *curses*) exec ${lib.getExe pkgs.pinentry-curses} "$@" ;;
    esac

    exec ${lib.getExe pkgs.pinentry-gnome3} "$@"
  '';
in {
  home = {
    packages = with pkgs; [
      # --- CORE DEPENDENCIES ---
      gcc
      gnumake
      tree-sitter

      # --- LANGUAGES & TOOLCHAINS ---
      docker-compose
      nodejs
      python3

      # --- DATA & FORMATTING ---
      sqlite

      # --- LSPs & LINTERS ---
      bash-language-server
      shellcheck
      luajitPackages.lua-lsp
      nixd # Nix LSP (eval-aware; supersedes the older nil)
      # alejandra lives in home/shell/packages.nix under NIX TOOLS
      gopls # Go LSP
      typescript-language-server # JS/TS LSP
      taplo # TOML LSP + formatter

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
      # profile tools (rm-improved, etc.).
      # Wraps use_flake to re-prepend user profile after devshell PATH.
      ".config/direnv/lib/zz-user-path.sh".text = ''
        eval "_original_$(declare -f use_flake)"
        use_flake() {
          _original_use_flake "$@"
          local ret=$?
          PATH_add ${
          if pkgs.stdenv.isDarwin
          then "/run/current-system/sw/bin"
          else "/etc/profiles/per-user/$USER/bin"
        }
          return $ret
        }
      '';

      # Host-agnostic flake-template selector for shared project .envrc files.
      # The dotfiles checkout path differs per host (lib/user.nix), so bake the
      # correct path here per-host; a shared .envrc just calls
      # `use_dotflake <template>` and resolves right on whichever host opens it.
      ".config/direnv/lib/use_dotflake.sh".text = ''
        use_dotflake() {
          use flake "${userConfig.dotfilesDirFor pkgs}/templates#''${1:?use_dotflake: template name required}"
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

      # Global excludes via core.excludesfile — applies in every repo.
      ignores = [
        "**/.claude/settings.local.json"
        ".antigravitycli/"
      ];

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
        credential.helper =
          if pkgs.stdenv.isDarwin
          then "osxkeychain"
          else "libsecret";
        safe.directory = userConfig.dotfilesDirFor pkgs;

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

    # --- GITHUB CLI ---
    gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
        editor = "nvim";
      };
      gitCredentialHelper.enable = true;
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
    pinentry.package =
      if pkgs.stdenv.isDarwin
      then pkgs.pinentry_mac
      else pinentry-auto;
    defaultCacheTtl = 3600;
    # Grabbing the keyboard and mouse breaks the curses prompt that tmux
    # sessions fall back to, and offers nothing for the GUI dialog here.
    grabKeyboardAndMouse = false;
    extraConfig = ''
      allow-preset-passphrase
    '';
  };
}
