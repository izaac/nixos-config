{
  userConfig,
  ...
}: let
  cleanPath = "/run/wrappers/bin:/etc/profiles/per-user/$USER/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/usr/bin:/bin";
in {
  programs.bash.initExtra = ''
    # --- BRUSH COMPATIBILITY FUNCTIONS (replaces chained aliases) ---
    ks() { sudo sh -c "sync; echo 1 > /proc/sys/vm/drop_caches" && echo "RAM cache cleared"; }
    ncl-full() { direnv prune && nh clean all --keep 10; }
    gpg-fix() { gpgconf --kill gpg-agent && rm -f ~/.gnupg/*.lock ~/.gnupg/public-keys.d/*.lock && echo 'GPG Fixed'; }

    er-offline() {
      cd /mnt/data/SteamLibrary/steamapps/common/ELDEN\ RING/Game && \
      if [ -f start_protected_game.exe ] && [ ! -f start_protected_game_original.exe ]; then
        mv start_protected_game.exe start_protected_game_original.exe && \
        cp eldenring.exe start_protected_game.exe && \
        echo 'Elden Ring Offline Mode (EAC Bypass) ENABLED'
      else
        echo 'Already in offline mode or Game path not found'
      fi
    }

    er-online() {
      cd /mnt/data/SteamLibrary/steamapps/common/ELDEN\ RING/Game && \
      if [ -f start_protected_game_original.exe ]; then
        rm start_protected_game.exe && \
        mv start_protected_game_original.exe start_protected_game.exe && \
        echo 'Elden Ring Online Mode (EAC) RESTORED'
      else
        echo 'Already in online mode or Game path not found'
      fi
    }

    # --- AI HELPERS ---
    # monko: ask Gemini for help in caveman talk
    monko() {
      if [[ $# -eq 0 ]]; then
        echo "Monko need words to think! Use: monko <what is wrong?>"
        return 1
      fi
      ask "Explain this like a caveman named Monko: $*"
    }

    # ask-monko: pipe previous command error to Gemini
    ask-monko() {
      local last_cmd=$(history | tail -n 2 | head -n 1 | sed 's/^[ ]*[0-9]*[ ]*//')
      echo "Monko looking at: $last_cmd"
      ask "I ran '$last_cmd' and it failed. Explain why like a caveman named Monko and suggest a fix."
    }

    # command_not_found_handle: Monko offer help
    command_not_found_handle() {
      echo "Monko not know command: $1"
      echo "Maybe you want: monko why $1 not work?"
      return 127
    }

    # --- Gemin / Copilot Wrappers ---
    ask() {
      if [[ $# -eq 0 ]]; then
        PATH="${cleanPath}" gemini
      else
        PATH="${cleanPath}" gemini -p "$*"
      fi
    }

    ai() {
      case "$1" in
        "") PATH="${cleanPath}" copilot ;;
        login|init|update|version|help) PATH="${cleanPath}" copilot "$@" ;;
        *) PATH="${cleanPath}" copilot -p "$*" ;;
      esac
    }

    # --- Fast Package Search ---
    nqs() {
      if [[ $# -eq 0 ]]; then
        echo "Usage: nqs <query...>"
        return 2
      fi
      nh search --limit 50 "$@"
    }

    # --- Smart Eza ---
    _smart_eza() {
      if [[ "$PWD" == *"/mnt/storage"* ]] || [[ "$*" == *"/mnt/storage"* ]]; then
        local args=()
        for arg in "$@"; do
          [[ "$arg" != "--git" ]] && [[ "$arg" != "-g" ]] && args+=("$arg")
        done
        command eza --icons=never --color=never "''${args[@]}"
      else
        command eza --icons=auto "$@"
      fi
    }

    # --- Yazi Wrapper ---
    y() {
      local tmp
      tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
      yazi "$@" --cwd-file="$tmp"
      if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
      fi
      rm -f -- "$tmp"
    }

    # --- Recursive Cat ---
    catr() {
      local target="''${1:-.}"
      rg --files --hidden -g '!.git' "$target" -0 | xargs -0 -I {} sh -c '
        if file -b --mime-type "{}" | grep -q "^text/"; then
          echo "================================================================================"
          echo "FILE: {}"
          echo "================================================================================"
          cat "{}"
          echo -e "\n"
        fi
      '
    }

    # --- Project Initializers ---
    ninit() {
      local ver="''${1:-}"
      local target="node"
      if [ -n "$ver" ]; then target="node_$ver"; fi
      cat <<ENVRC > .envrc
    use flake ${userConfig.dotfilesDir}/templates#$target
    watch_file package.json
    watch_file yarn.lock
    watch_file pnpm-lock.yaml
    if [ -f "package.json" ] && [ ! -d "node_modules" ]; then
      if [ -f "pnpm-lock.yaml" ]; then pnpm install;
      elif [ -f "yarn.lock" ]; then yarn install;
      else npm install; fi
    fi
    ENVRC
      direnv allow
    }

    pinit() {
      cat <<'ENVRC' > .envrc
    use flake ${userConfig.dotfilesDir}/templates#python
    watch_file requirements.txt
    watch_file pyproject.toml
    if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
      if [ ! -d ".venv" ] && [ -f "requirements.txt" ]; then
        uv venv && uv pip install -r requirements.txt
      fi
    fi
    ENVRC
      direnv allow
    }

    rinit() {
      cat <<'ENVRC' > .envrc
    use flake ${userConfig.dotfilesDir}/templates#rust
    watch_file Cargo.toml
    watch_file Cargo.lock
    ENVRC
      direnv allow
    }

    cinit() {
      cat <<'ENVRC' > .envrc
    use flake ${userConfig.dotfilesDir}/templates#c
    watch_file CMakeLists.txt
    watch_file Makefile
    ENVRC
      direnv allow
    }

    cppinit() {
      cat <<'ENVRC' > .envrc
    use flake ${userConfig.dotfilesDir}/templates#cpp
    watch_file CMakeLists.txt
    watch_file Makefile
    ENVRC
      direnv allow
    }
  '';
}
