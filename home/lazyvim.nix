{
  pkgs,
  lib,
  ...
}: {
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
      #
      # Because Mason is disabled (see disable-mason.lua below), every tool the
      # enabled language extras expect must be on this wrapper PATH, otherwise
      # the extra errors when it tries to spawn a missing binary. The LSPs we
      # already share come from home/dev.nix (nixd, gopls, taplo); the rest are
      # bundled here. DAP debuggers (delve, debugpy, js-debug) are intentionally
      # omitted since no nvim-dap extra is imported.
      lazygit

      # Lua (not an extra, but fully wired)
      lua-language-server
      stylua

      # Go extra (lang.go): linter and formatters. gopls is on PATH via
      # home/dev.nix. goimports ships inside gotools.
      golangci-lint
      gofumpt
      gotools

      # TypeScript extra (lang.typescript): vtsls is the LSP the extra selects
      # by default and force-enables over ts_ls.
      vtsls

      # Python extra (lang.python): pyright is the default LSP, ruff the linter
      # and formatter.
      pyright
      ruff

      # Markdown extra (lang.markdown): marksman is the LSP, markdownlint-cli2
      # the linter, prettier and markdown-toc the formatters. markdownlint-cli2
      # and prettier match the versions the repo's own treefmt and pre-commit
      # hooks use.
      marksman
      markdownlint-cli2
      prettier
      markdown-toc
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

    # Prefix-free increment/decrement. Neovim's native Ctrl+A is swallowed by
    # the tmux prefix (see docs/lazyvim.md), so bind + and - instead. Their
    # native line-motion is redundant with j/k and Enter, so reclaiming them
    # costs nothing and reads as plus = increment, minus = decrement.
    "nvim/lua/config/keymaps.lua".text = ''
      vim.keymap.set("n", "+", "<C-a>", { desc = "Increment number" })
      vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement number" })
      vim.keymap.set("x", "+", "g<C-a>", { desc = "Increment sequence" })
      vim.keymap.set("x", "-", "g<C-x>", { desc = "Decrement sequence" })
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

    # Align the Nix tooling with the rest of the repo. The lang.nix extra
    # defaults to the nil_ls language server and the nixfmt formatter, but the
    # CLI, treefmt and pre-commit hooks all use nixd (eval-aware, installed via
    # home/dev.nix) and alejandra. Point the editor at the same pair so an
    # in-editor save formats a file identically to `nix fmt`, with no churn.
    "nvim/lua/plugins/nix-tools.lua".text = ''
      return {
        {
          "neovim/nvim-lspconfig",
          opts = {
            servers = {
              nixd = {},
              nil_ls = { enabled = false },
            },
          },
        },
        {
          "stevearc/conform.nvim",
          optional = true,
          opts = function(_, opts)
            opts.formatters_by_ft = opts.formatters_by_ft or {}
            opts.formatters_by_ft.nix = { "alejandra" }
          end,
        },
      }
    '';
  };

  # The neovim package ships nvim.desktop with Terminal=true, and the vim
  # package ships vim.desktop the same way, but niri has no default terminal
  # for the file manager to resolve, so "Open with" silently fails. Override
  # both entries to launch Kitty explicitly, matching the yazi/btop pattern in
  # home/shell/env.nix. The vim alias resolves to Neovim (viAlias/vimAlias), so
  # both entries open the same editor.
  xdg.desktopEntries = lib.mkIf pkgs.stdenv.isLinux (let
    editorMimeTypes = [
      "text/plain"
      "text/markdown"
      "text/x-log"
      "application/x-shellscript"
      "text/x-c"
      "text/x-c++"
      "text/x-python"
    ];
  in {
    nvim = {
      name = "Neovim wrapper";
      genericName = "Text Editor";
      comment = "Edit text files";
      exec = "kitty nvim %F";
      icon = "nvim";
      terminal = false;
      categories = ["Utility" "TextEditor" "Development"];
      mimeType = editorMimeTypes;
      settings.Keywords = "Text;editor;vim;neovim;";
    };
    vim = {
      name = "Vim";
      genericName = "Text Editor";
      comment = "Edit text files";
      exec = "kitty vim %F";
      icon = "gvim";
      terminal = false;
      categories = ["Utility" "TextEditor"];
      mimeType = editorMimeTypes;
      settings.Keywords = "Text;editor;vim;";
    };
  });
}
