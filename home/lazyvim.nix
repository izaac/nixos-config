{pkgs, ...}: {
  # LazyVim ships its own colorscheme (tokyonight); skip stylix's neovim
  # target so the two don't fight at startup.
  stylix.targets.neovim.enable = false;

  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;

    extraPackages = with pkgs; [
      # LazyVim dependencies
      lazygit
      ripgrep
      fd

      # Build tools often needed by Mason/Lazy
      gnumake
      gcc
      unzip
      tree-sitter

      # Language servers / Formatters
      lua-language-server
      stylua
    ];
  };

  # Bootstrap LazyVim. Lazy plugin manager is provided by Nix so no runtime
  # git clone is needed; LazyVim itself still pulls plugin specs at first run.
  xdg.configFile = {
    "nvim/init.lua".text = ''
      require("config.lazy")
    '';

    "nvim/lua/config/lazy.lua".text = ''
      local lazypath = "${pkgs.vimPlugins.lazy-nvim}"
      vim.opt.rtp:prepend(lazypath)

      require("lazy").setup({
        spec = {
          { "LazyVim/LazyVim", import = "lazyvim.plugins" },
          { import = "plugins" },
        },
        defaults = {
          lazy = false,
          version = false,
        },
        install = { colorscheme = { "tokyonight", "habamax" } },
        checker = { enabled = false },
        performance = {
          rtp = {
            disabled_plugins = {
              "gzip",
              "tarPlugin",
              "tohtml",
              "tutor",
              "zipPlugin",
            },
          },
        },
      })
    '';

    "nvim/lua/config/options.lua".text = ''
      vim.g.mapleader = " "
    '';

    "nvim/lua/plugins/example.lua".text = ''
      return {}
    '';
  };
}
