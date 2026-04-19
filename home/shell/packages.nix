{
  pkgs,
  lib,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    # --- CORE CLI UTILS ---
    (lib.hiPrio uutils-coreutils-noprefix)
    jaq
    sd
    choose
    rm-improved
    procs
    pv
    bc
    just

    # --- FILE & TEXT SEARCH ---
    fd
    ripgrep
    ast-grep

    # --- DISK & FILE USAGE ---
    dust
    gdu

    # --- VIEWERS & PAGERS ---
    viddy
    hexyl
    mdcat
    man-db

    # --- NETWORK & DIAGNOSTICS ---
    trippy
    gping
    doggo
    xh
    lftp

    # --- CLOUD & CONTAINERS ---
    gh
    kubernetes-helm
    kubectl
    lazydocker
    rclone
    rsync

    # --- NIX TOOLS ---
    alejandra
    deadnix
    statix
    nix-tree
    comma
    nvd
    nix-init
    nix-melt
    nix-output-monitor
    nix-update
    nurl

    # --- SECURITY ---
    sops
    age

    # --- AI CLI TOOLS ---
    github-copilot-cli
    gemini-cli-bin
    claude-code
    # ai-trace-scanner is provided via overlay or direct input if needed

    # --- COMPRESSION & ARCHIVING ---
    ouch
    zip
    unzip
    p7zip
    xz
    zstd
    lz4
    gnutar
    gzip
    bzip2
    libarchive

    # --- TUI / WIDGETS ---
    ticker
    tenki
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    appimage-run
    wl-clipboard
    cliphist
    dwarfs
    fuse3
    nvtopPackages.nvidia
    bluetuith
  ];
}
