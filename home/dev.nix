{ pkgs, userConfig, ... }:

{
  home.packages = with pkgs; [
    # --- LAZYVIM DEPENDENCIES ---
    neovim
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
    
    # --- GUI IDEs ---
    (vscode.override {
      commandLineArgs = [
        "--enable-features=UseOzonePlatform"
        "--ozone-platform=wayland"
      ];
    })
    
    # --- UTILS ---
    tldr
  ];

  # --- GIT CONFIGURATION (25.11 FIXED) ---
  programs.git = {
    enable = true;
    
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
    mutableKeys = true;
    mutableTrust = true;
  };
  
  home.file.".gnupg/common.conf".text = "use-keyboxd";
  
  services.gpg-agent = {
    enable = true;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-gnome3;
    defaultCacheTtl = 3600;
  };

  # --- DIRENV ---
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableBashIntegration = true;
  };
}
