{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # --- LAZYVIM DEPENDENCIES ---
    neovim
    ripgrep
    fd
    lazygit
    gcc
    gnumake
    unzip
    wget
    curl
    tree-sitter
    xclip
    wl-clipboard
    
    # --- LANGUAGES & TOOLCHAINS ---
    fnm
    rustup
    go
    python3
    luarocks
    
    # --- DATA & FORMATTING ---
    sqlite
    jq
    
    # --- DOCUMENTATION & LATEX ---
    ghostscript
    tectonic
    texlive.combined.scheme-medium 
    
    # --- LSPs & LINTERS ---
    nodePackages.bash-language-server
    shellcheck
    luajitPackages.lua-lsp
    nil
    
    # --- GUI IDEs ---
    vscode
    
    # --- UTILS ---
    tldr
  ];

  # --- GIT CONFIGURATION ---
  # REFACTOR NOTE: Moved everything to 'settings' to match new Home Manager spec
  programs.git = {
    enable = true;
    
    settings = {
      # User Identity
      user = {
        name = "izaac";
        email = "izaac.zavaleta@suse.com";
        signingKey = "0x3183124333AB684C";
      };

      # Core Behavior
      init.defaultBranch = "main";
      commit.gpgsign = true;
      credential.helper = "store";
      safe.directory = "/home/izaac/Documents/repos/dashboard";

      # Aliases
      alias = {
        quickserve = "daemon --verbose --export-all --base-path=.git --reuseaddr --strict-paths .git/";
        logline = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      };
    };
  };

  # --- DELTA (Diff Tool) ---
  # REFACTOR NOTE: Delta is now a standalone module, not inside git
  programs.delta = {
    enable = true;
    enableGitIntegration = true; # Explicitly enabled to silence deprecation warning
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
    # REFACTOR NOTE: Fixed syntax from 'pinentryPackage' to 'pinentry.package'
    pinentry.package = pkgs.pinentry-gnome3;
    defaultCacheTtl = 3600;
  };
}

