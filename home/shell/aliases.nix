_: {
  programs.bash.shellAliases = {
    # --- CORE OVERRIDES ---
    ls = "ls --group-directories-first --color=auto";
    l = "_smart_eza -lb --git --group-directories-first";
    ll = "_smart_eza -l --group-directories-first";
    la = "_smart_eza -la --group-directories-first";
    lt = "_smart_eza --tree --level=2";

    # --- VIEWERS & DATA ---
    cat = "bat";
    jq = "jaq";
    sg = "ast-grep";
    hex = "hexyl";
    md = "mdcat";

    # --- NETWORK ---
    mtr = "trip";
    ping = "gping";
    curl = "xh";
    dig = "doggo";

    # --- SYSTEM & MONITORING ---
    top = "btop";
    sysls = "systemctl --type=service --state=running";

    # --- NAVIGATION & FILE OPS ---
    cpv = "rsync -ahP --size-only";
    rcp = "rclone sync --progress --fast-list --drive-chunk-size 64M --transfers 8 --checkers 16 --size-only";
    zlj = "zellij";

    # --- GIT ---
    gco = "git checkout";

    # --- NIX MANAGEMENT ---
    ncl = "nh clean all --keep 10 --nogc";
    nv-sys = "nvd diff $(command ls -vd /nix/var/nix/profiles/system-*-link | tail -2)";
    nv-boot = "nvd diff /run/booted-system /run/current-system";

    # --- TERMINAL FIXES & SECURITY ---
    ssh = "env TERM=xterm-256color ssh";

    # --- AI TOOLS ---
    ai-scan = "ai-trace-scan";
    ai-scan-staged = "ai-trace-scan --staged";
    ai-scan-wip = "ai-trace-scan --unstaged";

    # --- AUDIO ---
    pw-lowlat = "PIPEWIRE_LATENCY='512/48000'";
  };
}
