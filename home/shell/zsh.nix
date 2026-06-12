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

      ${builtins.readFile ./gpg-tty.sh}

      # SSH → persistent tmux session
      if [[ $- == *i* && -n "''${SSH_TTY-}" && -z "''${TMUX-}" && -z "''${VSCODE_INJECTION-}" ]]; then
        exec tmux new-session -A -s main
      fi
    '';
  };
}
