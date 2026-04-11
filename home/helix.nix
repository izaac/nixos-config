{pkgs, ...}: {
  programs.helix = {
    enable = true;
    defaultEditor = true;

    extraPackages = with pkgs; [
      # Git TUI
      gitui

      # Shell
      bash-language-server
      shfmt
      shellcheck

      # TypeScript / JavaScript (Cypress)
      typescript-language-server
      typescript
      prettierd

      # Python
      pyright
      ruff

      # Nix
      nil
      alejandra

      # YAML / Ansible
      yaml-language-server
      ansible-language-server

      # TOML
      taplo

      # JSON, CSS, HTML
      vscode-langservers-extracted

      # Markdown
      markdown-oxide
    ];

    settings = {
      editor = {
        line-number = "relative";
        cursorline = true;
        color-modes = true;
        true-color = true;
        bufferline = "multiple";
        auto-format = true;
        auto-save = true;
        idle-timeout = 250;

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        file-picker = {
          hidden = false;
          git-ignore = true;
        };

        indent-guides = {
          render = true;
          character = "▏";
        };

        lsp = {
          display-messages = true;
          display-inlay-hints = true;
        };

        statusline = {
          left = ["mode" "spinner" "file-name" "file-modification-indicator"];
          center = ["diagnostics"];
          right = ["selections" "position" "file-encoding" "file-line-ending" "file-type" "version-control"];
          separator = "│";
        };

        soft-wrap.enable = true;
      };

      keys = {
        normal = {
          "C-s" = ":write";
          "C-h" = "jump_view_left";
          "C-j" = "jump_view_down";
          "C-k" = "jump_view_up";
          "C-l" = "jump_view_right";
        };
        insert = {
          "C-s" = ":write";
        };
      };
    };

    languages = {
      language-server = {
        ruff = {
          command = "ruff";
          args = ["server"];
        };
        yaml-language-server = {
          config.yaml = {
            validation = true;
            schemaStore.enable = true;
          };
        };
      };

      language = [
        {
          name = "bash";
          auto-format = true;
          formatter = {
            command = "shfmt";
            args = ["-i" "2" "-ci"];
          };
        }
        {
          name = "typescript";
          auto-format = true;
          formatter = {
            command = "prettierd";
            args = ["--parser" "typescript"];
          };
        }
        {
          name = "javascript";
          auto-format = true;
          formatter = {
            command = "prettierd";
            args = ["--parser" "babel"];
          };
        }
        {
          name = "python";
          auto-format = true;
          language-servers = ["pyright" "ruff"];
          formatter = {
            command = "ruff";
            args = ["format" "-"];
          };
        }
        {
          name = "nix";
          auto-format = true;
          formatter = {
            command = "alejandra";
            args = ["-q"];
          };
        }
        {
          name = "json";
          auto-format = true;
          formatter = {
            command = "prettierd";
            args = ["--parser" "json"];
          };
        }
        {
          name = "markdown";
          auto-format = true;
          formatter = {
            command = "prettierd";
            args = ["--parser" "markdown"];
          };
        }
      ];
    };
  };
}
