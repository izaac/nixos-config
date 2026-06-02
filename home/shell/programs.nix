{pkgs, ...}: {
  programs = {
    starship = {
      enable = true;
      package = pkgs.starship;
      settings = {
        command_timeout = 500;
        add_newline = false;
        format = "$directory$hostname$git_branch$git_status$env_var$character";
        character = {
          success_symbol = "[](bold green) ";
          error_symbol = "[](bold red) ";
          vimcmd_symbol = "[](bold yellow) ";
        };
        hostname = {
          ssh_only = true;
          format = "on [$hostname]($style) ";
          style = "bold dimmed white";
          aliases = {
            "windy" = "󰌢 windy";
            "ninja" = "󰟀 ninja";
          };
        };
        container.disabled = true;
        env_var.CONTAINER_ID = {
          format = "[⬢ \\[$env_value\\]]($style) ";
          style = "bold yellow";
        };
      };
    };

    atuin = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        auto_sync = false;
        style = "compact";
        inline_height = 20;
        filter_mode = "global";
        filter_mode_shell_up = "directory";
        search_mode = "fuzzy";
        enter_accept = false;
        workspaces = true;
      };
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = ["--cmd" "cd"];
    };

    yazi = {
      enable = true;
      enableZshIntegration = true;
      shellWrapperName = "y";
    };

    eza = {
      enable = true;
      enableZshIntegration = true;
      icons = "auto";
      git = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "fd --type f";
      fileWidgetCommand = "fd --type f";
      changeDirWidgetCommand = "fd --type d";
    };

    bat = {
      enable = true;
      config = {
        style = "plain";
        paging = "never";
      };
    };

    tealdeer = {
      enable = true;
      settings = {
        display = {
          compact = true;
          use_pager = true;
        };
        updates = {
          auto_update = true;
        };
      };
    };

    btop = {
      enable = true;
      settings = {
        theme_background = false;
        update_ms = 500;
        proc_sorting = "cpu lazy";
      };
    };

    nix-index = {
      enable = true;
      enableZshIntegration = true;
    };

    bash = {
      enable = true;
      enableCompletion = true;
    };
  };
}
