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
      # LazyVim-specific deps. ripgrep/fd/gnumake/gcc/unzip/tree-sitter live
      # on user PATH via home/dev.nix + home/shell/packages.nix — neovim
      # finds them there, so no need to duplicate into the wrapper.
      lazygit

      # Language servers / Formatters not shared with other tools
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
          -- Language extras (need matching LSPs on PATH via home/dev.nix)
          { import = "lazyvim.plugins.extras.lang.nix" },
          { import = "lazyvim.plugins.extras.lang.go" },
          { import = "lazyvim.plugins.extras.lang.typescript" },
          { import = "lazyvim.plugins.extras.lang.python" },
          { import = "lazyvim.plugins.extras.lang.toml" },
          { import = "lazyvim.plugins.extras.lang.markdown" },
          { import = "plugins" },
        },
        defaults = {
          lazy = false,
          version = false,
        },
        install = { colorscheme = { "catppuccin-mocha", "habamax" } },
        checker = { enabled = false },
        -- Plugin specs come from immutable Nix store paths; the rebuild bumps
        -- the path on every HM switch and lazy.nvim emits noisy "config
        -- changed" reload prompts. Disable detection entirely.
        change_detection = {
          enabled = false,
          notify = false,
        },
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

    "nvim/lua/plugins/colorscheme.lua".text = ''
      return {
        { "catppuccin/nvim", name = "catppuccin", priority = 1000 },
        {
          "LazyVim/LazyVim",
          opts = { colorscheme = "catppuccin-mocha" },
        },
      }
    '';

    # Disable Mason entirely. Mason downloads prebuilt ELF binaries that
    # need a glibc FHS layout — broken on NixOS. nvim-lspconfig keeps
    # running and picks up LSPs/formatters from system PATH (installed
    # via home/dev.nix + home/shell/packages.nix).
    "nvim/lua/plugins/disable-mason.lua".text = ''
      return {
        { "mason-org/mason.nvim", enabled = false },
        { "mason-org/mason-lspconfig.nvim", enabled = false },
        { "WhoIsSethDaniel/mason-tool-installer.nvim", enabled = false },
        { "jay-babu/mason-nvim-dap.nvim", enabled = false },
      }
    '';
  };
}
