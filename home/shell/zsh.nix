{
  pkgs,
  config,
  ...
}: {
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";
    enableCompletion = true;
    # Only rebuild the completion dump once a day. Home-manager's default
    # `compinit` rescans the entire nix-store fpath on every shell start
    # (~1.8s here); `compinit -C` trusts the cached dump and is near-instant.
    completionInit = ''
      autoload -Uz compinit
      () {
        emulate -L zsh
        setopt extended_glob
        local zdump=''${ZDOTDIR:-$HOME}/.zcompdump
        local -a stale=( $zdump(N.mh+24) )
        if (( $#stale )) || [[ ! -s $zdump ]]; then
          compinit -d $zdump
        else
          compinit -C -d $zdump
        fi
      }
    '';
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
