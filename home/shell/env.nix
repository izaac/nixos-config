{ lib, pkgs, userConfig, ... }: {
  home = {
    sessionVariables = {
      PAGER = "bat";
      DIRENV_LOG_FORMAT = "";
      TERMINAL = "wezterm";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      ATUIN_NO_MODIFY_DB = "true";
      QA_INFRA_DIR = "/home/${userConfig.username}/repos/qa-infra-automation";
    };

    file = {
      ".brushrc".text = ''
        if type starship_precmd &>/dev/null; then
          PROMPT_COMMAND="starship_precmd;''${PROMPT_COMMAND:-}"
        fi
      '';
    };
  };

  xdg = {
    configFile."lftp/rc".text = ''
      set sftp:max-packets-in-flight 32
      set net:socket-buffer 2097152
      set net:socket-maxseg 1440
      set mirror:parallel-directories yes
      set mirror:parallel-transfer-count 2
      set pget:default-n 5
      set net:connection-limit 10
      set net:connection-takeover yes
    '';

    configFile."brush/config.toml".text = ''
      [ui]
      syntax-highlighting = true

      [experimental]
      zsh-hooks = true
    '';

    desktopEntries = lib.mkIf pkgs.stdenv.isLinux {
      yazi = {
        name = "Yazi";
        exec = "wezterm start -- yazi %u";
        icon = "yazi";
        terminal = false;
        categories = ["Utility" "Core" "System" "FileTools" "FileManager" "ConsoleOnly"];
        mimeType = ["inode/directory"];
        settings = {
          Keywords = "File;Manager;Explorer;Browser;Launcher";
        };
      };

      btop = {
        name = "btop++";
        exec = "wezterm start -- btop";
        icon = "btop";
        terminal = false;
        categories = ["System" "Monitor" "ConsoleOnly"];
        settings = {
          Keywords = "system;process;task";
        };
      };
    };
  };
}
