{
  description = "Izaac's Personal Flake Templates & Golden Master Shells";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
  };

  outputs = { self, nixpkgs, devenv }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};
    in
    {
      # 1. GOLDEN MASTER SHELLS (Quick, ephemeral shells)
      # Use: nix develop github:<username>/nixos-config?dir=templates#rust
      devShells = forAllSystems (system:
        let
          pkgs = pkgsFor system;

          # Helper to create a Node shell with correctly bound tools
          mkNodeShell = nodePkg: pkgs.mkShell {
            packages = [
              nodePkg
              (pkgs.pnpm.override { nodejs = nodePkg; })
              (pkgs.yarn.override { nodejs = nodePkg; })
            ];
            shellHook = ''
              echo "Node.js ${nodePkg.version} Shell"
              echo "  - Node: $(node --version)"
              echo "  - Yarn: $(yarn --version)"
              echo "  - Pnpm: $(pnpm --version)"
            '';
          };
        in {
          # --- PYTHON ---
          python     = pkgs.mkShell { packages = [ pkgs.python3 pkgs.uv ]; shellHook = "echo 'Python (Default) Shell'"; };
          python_310 = pkgs.mkShell { packages = [ pkgs.python310 pkgs.uv ]; shellHook = "echo 'Python 3.10 Shell'"; };
          python_311 = pkgs.mkShell { packages = [ pkgs.python311 pkgs.uv ]; shellHook = "echo 'Python 3.11 Shell'"; };
          python_312 = pkgs.mkShell { packages = [ pkgs.python312 pkgs.uv ]; shellHook = "echo 'Python 3.12 Shell'"; };

          # --- RUST ---
          rust = pkgs.mkShell {
            packages = with pkgs; [
              cargo
              rustc
              rust-analyzer
              clippy
              rustfmt
            ];
            shellHook = "echo 'Rust (Stable) Shell'";
          };

          # --- C/C++ ---
          c = pkgs.mkShell {
            packages = with pkgs; [
              gcc
              cmake
              ninja
              pkg-config
              gdb
            ];
            shellHook = "echo 'C/C++ Shell'";
          };

          cpp = pkgs.mkShell {
            packages = with pkgs; [
              clang
              cmake
              ninja
              pkg-config
              lldb
              clang-tools  # clangd, clang-format, clang-tidy
            ];
            shellHook = "echo 'C++ (Clang) Shell'";
          };

          # --- NODE.JS ---
          node       = mkNodeShell pkgs.nodejs;      # Default (currently v22)
          node_20    = mkNodeShell pkgs.nodejs_20;
          node_22    = mkNodeShell pkgs.nodejs_22;
          node_24    = mkNodeShell pkgs.nodejs_24;
        });

      # 2. TEMPLATES (Project scaffolding with devenv)
      # Use: nix flake init -t github:<username>/nixos-config?dir=templates#rust
      templates = {
        python = {
          path = ./python;
          description = "Python development environment with devenv";
        };

        rust = {
          path = ./rust;
          description = "Rust development environment with devenv";
        };

        c = {
          path = ./c;
          description = "C development environment with devenv";
        };

        cpp = {
          path = ./cpp;
          description = "C++ development environment with devenv";
        };

        node = {
          path = ./node;
          description = "Node.js development environment with devenv";
        };
      };
    };
}
