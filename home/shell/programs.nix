{pkgs, ...}: {
  programs = {
    starship = {
      enable = true;
      package = pkgs.starship;
      settings = {
        command_timeout = 500;
        add_newline = false;
        format = "$directory$hostname$git_branch$git_status$container$character";
        character = {
          success_symbol = "[](bold green) ";
          error_symbol = "[](bold red) ";
          vimcmd_symbol = "[](bold yellow) ";
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
      };
    };

    atuin = {
      enable = true;
      enableBashIntegration = true;
      settings = {
        auto_sync = false;
        style = "compact";
        inline_height = 20;
        filter_mode = "global";
        filter_mode_shell_up = "global";
        search_mode = "fuzzy";
      };
    };

    zoxide = {
      enable = true;
      enableBashIntegration = true;
      options = ["--cmd" "cd"];
    };

    yazi = {
      enable = true;
      enableBashIntegration = true;
      shellWrapperName = "y";
    };

    eza = {
      enable = true;
      enableBashIntegration = true;
      icons = "auto";
      git = true;
    };

    skim = {
      enable = true;
      enableBashIntegration = true;
      defaultCommand = "fd --type f";
      fileWidgetCommand = "fd --type f";
      changeDirWidgetCommand = "fd --type d";
    };

    bat.enable = true;

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
      enableBashIntegration = true;
    };

    bash = {
      enable = true;
      enableCompletion = true;
      historySize = 50000;
      historyFileSize = 100000;
      historyControl = ["ignoredups" "ignorespace" "erasedups"];

      # --- DISTROBOX SHIELD (Must run before everything else) ---
      initExtra = pkgs.lib.mkBefore ''
        if [ -d "/run/host/nix/store" ]; then
          # 1. Early PATH injection (Host tools first to avoid 'command not found')
          export PATH="$HOME/.local/share/distrobox/bin:/run/host/run/current-system/sw/bin:/run/host/bin:/run/host/usr/bin:$PATH"

          # Inject host user profile binaries early
          host_user=$(readlink /run/host/etc/profiles/per-user/$USER)
          if [ -n "$host_user" ]; then
            host_user_resolved=$(readlink "/run/host$host_user")
            [ -z "$host_user_resolved" ] && host_user_resolved="$host_user"
            export PATH="$PATH:/run/host$host_user_resolved/bin"
          fi
          unset host_user host_user_resolved

          # 2. Atuin Container Reset
          unset ATUIN_NO_MODIFY_DB
          unset ATUIN_SHLVL
          unset ATUIN_PREEXEC_BACKEND

          # 3. Scrub PROMPT_COMMAND if it's already haunted
          _dbx_shield_scrub() {
            if declare -p PROMPT_COMMAND 2>/dev/null | grep -q "declare -a"; then
              local i
              for i in "''${!PROMPT_COMMAND[@]}"; do
                if [[ "''${PROMPT_COMMAND[$i]}" == *"_dbx_"* ]] || [[ "''${PROMPT_COMMAND[$i]}" == *"__bp_install"* ]]; then
                  unset 'PROMPT_COMMAND[$i]'
                fi
              done
            fi
          }
          _dbx_shield_scrub
          unset -f _dbx_shield_scrub
        fi
      '';

      sessionVariables = {
        EDITOR = "hx";
        VISUAL = "hx";
      };
    };
  };
}
