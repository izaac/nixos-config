{
  pkgs,
  lib,
  inputs,
  osConfig ? {},
  ...
}: let
  hostname = osConfig.networking.hostName or "";
  system = pkgs.stdenv.hostPlatform.system;
in {
  home.packages = with pkgs;
    [
      # --- CORE CLI UTILS ---
      jq
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
      duf

      # --- VIEWERS & PAGERS ---
      viddy
      hexyl
      mdcat
      glow
      man-db

      # --- NETWORK & DIAGNOSTICS ---
      trippy
      gping
      doggo
      lftp
      mosh
      cloudflared

      # --- BENCHMARKING ---
      hyperfine

      # --- CLOUD & CONTAINERS ---
      gh
      kubernetes-helm
      kubectl
      k9s
      k3d
      lazydocker
      skopeo
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
      claude-code
      ai-trace-scanner
      opencode

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
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      appimage-run
      wl-clipboard
      wl-clip-persist
      dwarfs
      fuse3
      nvtopPackages.nvidia
      bluetuith
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      # GNU userland for Linux-parity in interactive shell.
      # Aliased (not PATH-prepended) so scripts using BSD defaults stay intact.
      coreutils
      findutils
      gnused
      gnugrep
      gawk
      gnumake
      moreutils
      watch
      pstree
      lsof
    ]
    ++ [
      inputs.nix-packages.packages.${system}.proton-drive-cli
      inputs.nix-packages.packages.${system}.pd
    ]
    ++ lib.optionals (hostname == "ninja") [
      codex
    ];
}
