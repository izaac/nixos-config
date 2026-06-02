{
  pkgs,
  config,
  ...
}: {
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 50000;
      save = 100000;
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
      share = true;
    };

    historySubstringSearch.enable = true;

    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab + "/share/fzf-tab";
      }
    ];

    initContent = ''
      # Autocd
      setopt autocd

      # GPG TTY FIX
      current_tty=$(tty 2>/dev/null)
      if [[ "$current_tty" != "not a tty" ]]; then
        export GPG_TTY="$current_tty"
      fi
      unset current_tty

      # SSH → persistent tmux session
      if [[ $- == *i* && -n "''${SSH_TTY-}" && -z "''${TMUX-}" && -z "''${VSCODE_INJECTION-}" ]]; then
        exec tmux new-session -A -s main
      fi
    '';
  };
}
