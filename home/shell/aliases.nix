{
  pkgs,
  lib,
  ...
}: {
  programs.zsh.shellAliases =
    {
      # --- CORE OVERRIDES ---
      ls = "ls --group-directories-first --color=auto";
      l = "_smart_eza -lb --git --group-directories-first";
      ll = "_smart_eza -l --group-directories-first";
      la = "_smart_eza -la --group-directories-first";
      lt = "_smart_eza --tree --level=2";

      # --- VIEWERS & DATA ---
      sg = "ast-grep";
      hex = "hexyl";
      md = "mdcat";

      # --- NETWORK ---
      mtr = "trip";
      ping = "gping";
      dig = "doggo";

      # --- SYSTEM & MONITORING ---
      top = "btop";
      sysls = "systemctl --type=service --state=running";

      # --- PLEX (on-demand) ---
      plex-start = "systemctl start plex";
      plex-stop = "systemctl stop plex";
      plex-status = "systemctl status plex";

      # --- NAVIGATION & FILE OPS ---
      cpv = "rsync -ahP --size-only";
      rcp = "rclone sync --progress --fast-list --drive-chunk-size 64M --transfers 8 --checkers 16 --size-only";

      # --- GIT ---
      gco = "git checkout";

      # --- NIX MANAGEMENT ---
      ncl = "nh clean all --keep 10 --nogc";
      nv-boot = "nvd diff /run/booted-system /run/current-system";

      # --- TERMINAL FIXES & SECURITY ---
      ssh = "env TERM=xterm-256color ssh";

      # --- AI TOOLS ---
      claude = "env CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 claude";
      ai-scan = "ai-trace-scan";
      ai-scan-staged = "ai-trace-scan --staged";
      ai-scan-wip = "ai-trace-scan --unstaged";

      # --- AUDIO ---
      pw-lowlat = "PIPEWIRE_LATENCY='512/48000'";
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
      ls = "${pkgs.coreutils}/bin/ls --group-directories-first --color=auto";
      sed = "${pkgs.gnused}/bin/sed";
      grep = "${pkgs.gnugrep}/bin/grep --color=auto";
      egrep = "${pkgs.gnugrep}/bin/grep -E --color=auto";
      fgrep = "${pkgs.gnugrep}/bin/grep -F --color=auto";
      awk = "${pkgs.gawk}/bin/awk";
      find = "${pkgs.findutils}/bin/find";
      xargs = "${pkgs.findutils}/bin/xargs";
      make = "${pkgs.gnumake}/bin/make";
      readlink = "${pkgs.coreutils}/bin/readlink";
      date = "${pkgs.coreutils}/bin/date";
      du = "${pkgs.coreutils}/bin/du";
      df = "${pkgs.coreutils}/bin/df";
      stat = "${pkgs.coreutils}/bin/stat";
      cp = "${pkgs.coreutils}/bin/cp";
      mv = "${pkgs.coreutils}/bin/mv";
      rm = "${pkgs.coreutils}/bin/rm";
      wl-copy = "pbcopy";
      wl-paste = "pbpaste";
      xdg-open = "open";
    };
}
