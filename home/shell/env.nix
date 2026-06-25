{
  config,
  lib,
  pkgs,
  ...
}: {
  home = {
    sessionVariables =
      {
        PAGER = "less";
        DIRENV_LOG_FORMAT = "";
        TERMINAL = "kitty";
        ATUIN_NO_MODIFY_DB = "true";
        QA_INFRA_DIR = "${config.home.homeDirectory}/repos/qa-infra-automation";
        PROTON_PASS_KEY_PROVIDER = "fs";
      }
      // lib.optionalAttrs pkgs.stdenv.isLinux {
        # Idiomatic single switch so every Electron/Chromium app runs natively
        # on Wayland (niri) instead of XWayland. Replaces per-app ozone flags.
        # Linux-only: meaningless on macOS.
        NIXOS_OZONE_WL = "1";
      };

    # Propagate user-local bin dirs to every launcher — niri spawn, desktop
    # entries, systemd user units — not just interactive bash.
    sessionPath =
      lib.optionals pkgs.stdenv.isDarwin [
        "/opt/homebrew/bin"
      ]
      ++ [
        "$HOME/.local/bin"
        "$HOME/bin"
      ];
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

    desktopEntries = lib.mkIf pkgs.stdenv.isLinux {
      yazi = {
        name = "Yazi";
        exec = "kitty yazi %u";
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
        exec = "kitty btop";
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
