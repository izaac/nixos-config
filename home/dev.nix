{ pkgs, userConfig, ... }:

{
  home.packages = with pkgs; [
    # --- LAZYVIM DEPENDENCIES ---
    gcc
    gnumake
    tree-sitter
    
    # --- LANGUAGES & TOOLCHAINS ---
    docker-compose
    
    # --- DATA & FORMATTING ---
    sqlite
    
    # --- LSPs & LINTERS ---
    nodePackages.bash-language-server
    shellcheck
    luajitPackages.lua-lsp
    nil
    
    # --- UTILS ---
    unstable.gemini-cli
  ];

  # --- GIT CONFIGURATION (25.11 FIXED) ---
  programs.git = {
    enable = true;
    package = pkgs.git;
    
    # Signing remains a top-level attribute in Home Manager for now
    signing = {
      key = userConfig.gitKey;
      signByDefault = true;
    };

    # Everything else moves into 'settings'
    settings = {
      user = {
        name = userConfig.name;
        email = userConfig.email;
      };

      init.defaultBranch = "main";
      credential.helper = "libsecret";
      safe.directory = "*";

      # Note the singular 'alias' key under settings
      alias = {
        quickserve = "daemon --verbose --export-all --base-path=.git --reuseaddr --strict-paths .git/";
        logline = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      };
    };
  };

  # --- DELTA (Diff Tool) ---
  programs.delta = {
    enable = true;
    package = pkgs.delta;
    enableGitIntegration = true; 
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = true;
    };
  };

  # --- LAZYGIT ---
  programs.lazygit = {
    enable = true;
    package = pkgs.lazygit;
    settings = {
      gui = {
        theme = {
          activeBorderColor = [ "#a6e3a1" "bold" ];
          inactiveBorderColor = [ "#a6adc8" ];
          optionsTextColor = [ "#89b4fa" ];
          selectedLineBgColor = [ "#313244" ];
          selectedRangeBgColor = [ "#313244" ];
          cherryPickedCommitBgColor = [ "#45475a" ];
          cherryPickedCommitFgColor = [ "#a6e3a1" ];
          uploadDownloadArrowColor = [ "#f2cdcd" ];
          warningColor = [ "#fab387" ];
        };
      };
    };
  };

  # --- GPG ---
  programs.gpg = {
    enable = true;
    package = pkgs.gnupg;
    mutableKeys = true;
    mutableTrust = true;
  };
  
  home.file.".gnupg/common.conf".text = "use-keyboxd";
  home.file.".pam-gnupg".text = ''
    558F90AD0CFA39DB14CF2E9370073BF860AE0A2A
    9FE9496B3FF98EED829F2FD4BE0A07C5C64AA998
    841969EBFACD2E9E45FF7349BE991D37D7079FBF
  '';
  
  services.gpg-agent = {
    enable = true;
    enableSshSupport = false;
    pinentry.package = pkgs.pinentry-gnome3;
    defaultCacheTtl = 3600;
    extraConfig = ''
      allow-preset-passphrase
    '';
  };

  # --- DIRENV ---
  programs.direnv = {
    enable = true;
    package = pkgs.direnv;
    nix-direnv.enable = true;
    enableBashIntegration = true;
    
    # TOML configuration to surgically silence the export list.
    config = {
      global = {
        hide_env_diff = true; 
      };
    };
  };

}
