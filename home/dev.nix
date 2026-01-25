{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # --- LAZYVIM DEPENDENCIES ---
    neovim           # The binary (managed manually via ~/.config/nvim)
    ripgrep          # Fast grep
    fd               # Fast find
    lazygit          # Git TUI
    gcc              # C Compiler (needed for Treesitter)
    gnumake          # Make
    unzip
    wget
    curl
    tree-sitter      # Syntax highlighting core
    xclip            # Clipboard support (X11)
    wl-clipboard     # Clipboard support (Wayland)
    
    # --- LANGUAGES & TOOLCHAINS ---
    fnm              # Node.js Manager (Replaces system nodejs)
    go               # Go Lang
    python3          # Python (includes pip for venvs)
    luarocks         # Lua Package Manager
    
    # --- DATA & FORMATTING ---
    sqlite           # SQLite3
    jq               # JSON Processor
    
    # --- DOCUMENTATION & LATEX ---
    ghostscript      # 'gs' command
    tectonic         # Modern, self-contained LaTeX engine
    # Provides 'pdflatex' and standard packages (medium size)
    texlive.combined.scheme-medium 
    
    # --- LSPs & LINTERS ---
    nodePackages.bash-language-server
    shellcheck
    luajitPackages.lua-lsp
    nil              # Nix LSP (Best for editing .nix files)
    
    # --- GUI IDEs ---
    vscode
    
    # --- UTILS ---
    tldr
  ];

  # --- GIT ---
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "izaac";
        email = "jorge.izaac@gmail.com";
      };
    };
    signing = {
      # The explicit RSA 4096 Key ID you requested
      key = "0x3183124333AB684C"; 
      signByDefault = true;
    };
  };

  # --- LAZYGIT (Theme Config) ---
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
}
