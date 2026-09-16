{
  pkgs,
  lib,
  inputs,
  osConfig ? {},
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  isWorkstation = (osConfig.mySystem.desktop.enable or false) || pkgs.stdenv.isDarwin;
  hasNvidia = builtins.elem "nvidia" (osConfig.services.xserver.videoDrivers or []);
  hasBluetooth = osConfig.mySystem.core.bluetooth.enable or false;
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
      gdu # diskonaut not in nixpkgs; gdu kept
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
      doggo # dog (rust) removed from nixpkgs as unmaintained+insecure
      lftp
      mosh

      # --- BENCHMARKING ---
      hyperfine

      # --- CLOUD & CONTAINERS ---
      kubernetes-helm
      kubectl
      kdash # was k9s (Go) → kdash (Rust)
      k3d
      (oxker.overrideAttrs (_old: {doCheck = false;})) # skip broken macOS snapshot tests
      skopeo
      rclone
      rsync

      # --- NIX TOOLS ---
      alejandra
      deadnix
      statix
      nix-tree
      nvd
      nix-init
      nix-melt
      nix-output-monitor
      nix-update
      nurl

      # --- SECURITY ---
      sops
      age

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
    ++ lib.optionals isWorkstation [
      cloudflared
      github-copilot-cli
      claude-code
      opencode
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      fuse3
    ]
    ++ lib.optionals (pkgs.stdenv.isLinux && isWorkstation) [
      appimage-run
      wl-clipboard
      wl-clip-persist
      dwarfs
    ]
    ++ lib.optionals (pkgs.stdenv.isLinux && hasBluetooth) [
      bluetuith
    ]
    ++ lib.optionals (pkgs.stdenv.isLinux && hasNvidia) [
      nvtopPackages.nvidia
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
    ];
}
