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
        # Ship a copy without the compiled C `modules` directory so the plugin
        # works on pure-zsh setups and does not pull a broken prebuilt module.
        src = pkgs.runCommand "zsh-fzf-tab-nomodule" {} ''
          cp -r ${pkgs.zsh-fzf-tab}/share/fzf-tab $out
          chmod -R u+w $out
          rm -rf $out/modules
        '';
      }
    ];

    initContent = ''
      # Autocd
      setopt autocd

      # Unmatched globs must not abort the whole command line. zsh errors out
      # where bash leaves the pattern literal; NULL_GLOB drops it instead, which
      # keeps pasted bash-oriented commands from dying mid-line.
      setopt NULL_GLOB

      # Word navigation. xterm-256color terminfo ships no kLFT5/kRIT5, and zsh
      # leaves Ctrl+Left/Right unbound as a result, so the ESC[1 prefix gets
      # swallowed and the remainder arrives as literal ";5D". Bind both keymaps
      # explicitly rather than relying on "main", which follows VISUAL here and
      # can therefore be viins or emacs depending on the environment.
      bindkey -M emacs "^[[1;5D" backward-word
      bindkey -M emacs "^[[1;5C" forward-word
      bindkey -M emacs "^[[1;3D" backward-word
      bindkey -M emacs "^[[1;3C" forward-word
      bindkey -M viins "^[[1;5D" backward-word
      bindkey -M viins "^[[1;5C" forward-word
      bindkey -M viins "^[[1;3D" backward-word
      bindkey -M viins "^[[1;3C" forward-word

      ${builtins.readFile ./gpg-tty.sh}

      # SSH → persistent tmux session
      if [[ $- == *i* && -n "''${SSH_TTY-}" && -z "''${TMUX-}" && -z "''${VSCODE_INJECTION-}" ]]; then
        exec tmux new-session -A -s main
      fi
      if [[ "''${TMUX-}" == "skip" ]]; then
        unset TMUX
      fi

      # Container shells inherit no host profile, so atuin can be missing from
      # PATH. Fall back to the nix store binary when it exists.
      if ! command -v atuin >/dev/null 2>&1 && [ -x "${pkgs.atuin}/bin/atuin" ]; then
        export PATH="''$PATH:${pkgs.atuin}/bin"
      fi

      # Inside distrobox containers, bypass the interactive sudo wrapper below.
      # That wrapper forwards TERMINFO as an argv assignment, which glibc sudo
      # accepts but the OpenBSD sudo shipped by Chimera rejects outright
      # ("sudo: TERMINFO=...: command not found"). Alias expansion runs before
      # function lookup, so this wins however late the wrapper is defined.
      if [[ -n "''${container-}" ]]; then
        alias sudo='command sudo'
      fi
    '';
  };
}
