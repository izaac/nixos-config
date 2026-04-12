{
  pkgs,
  lib,
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
    duf
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

    # --- SECURITY ---
    sops
    age

    # --- AI CLI TOOLS ---
    github-copilot-cli
    gemini-cli-bin
    claude-code
    ai-trace-scanner

    # --- MEDIA & ENCODING ---
    # (inputs.nix-packages is handled in shell.nix)

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

    # --- SYSTEM & HARDWARE ---
    appimage-run
    wl-clipboard
    cliphist
    dwarfs
    fuse3
    nvitop
    nvtopPackages.nvidia
    bluetuith

    # --- TUI / WIDGETS ---
    ticker
    tenki
  ];
}
