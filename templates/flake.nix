{
  description = "Izaac's Personal Flake Templates & Golden Master Shells";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
  };

  outputs = {nixpkgs, ...}: let
    supportedSystems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    pkgsFor = system: nixpkgs.legacyPackages.${system};
  in {
    # 1. GOLDEN MASTER SHELLS (Quick, ephemeral shells)
    # Use: nix develop github:<username>/nixos-config?dir=templates#rust
    devShells = forAllSystems (system: let
      pkgs = pkgsFor system;

      # Helper to create a Node shell with correctly bound tools
      mkNodeShell = nodePkg:
        pkgs.mkShell {
          packages = [
            nodePkg
            (pkgs.pnpm.override {nodejs = nodePkg;})
            (pkgs.yarn.override {nodejs = nodePkg;})
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
      python = pkgs.mkShell {
        packages = [(pkgs.python3.withPackages (ps: [ps.tkinter])) pkgs.uv];
        shellHook = "echo 'Python (Default) Shell'";
      };
      python_310 = pkgs.mkShell {
        packages = [pkgs.python310 pkgs.uv];
        shellHook = "echo 'Python 3.10 Shell'";
      };
      python_311 = pkgs.mkShell {
        packages = [pkgs.python311 pkgs.uv];
        shellHook = "echo 'Python 3.11 Shell'";
      };
      python_312 = pkgs.mkShell {
        packages = [pkgs.python312 pkgs.uv];
        shellHook = "echo 'Python 3.12 Shell'";
      };

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
          clang-tools # clangd, clang-format, clang-tidy
        ];
        shellHook = "echo 'C++ (Clang) Shell'";
      };

      # --- NODE.JS ---
      node = mkNodeShell pkgs.nodejs; # Default (currently v22)
      node_20 = mkNodeShell pkgs.nodejs_20;
      node_22 = mkNodeShell pkgs.nodejs_22;
      node_24 = mkNodeShell pkgs.nodejs_24;

      # --- QA-INFRA-AUTOMATION (tofu + ansible + k8s tooling) ---
      # Use from the work repo via an (uncommitted) .envrc:
      #   use flake ~/nixos-config/templates#qa-infra --no-pure-eval
      qa-infra = let
        # The repo's playbooks are tested against the versions pinned in its
        # requirements.txt/requirements.yml. nixpkgs currently ships ansible-core
        # 2.20, whose 2.19+ data-tagging breaks community.general.json_query
        # ("invalid type ... received: unknown"), and a kubernetes/urllib3 combo
        # that trips "'HTTPResponse' object has no attribute 'getheaders'".
        # So instead of a nixpkgs python env we bootstrap a pip venv pinned to
        # ansible-core < 2.19 plus the libraries the playbooks import. Nix only
        # provides the interpreter used to build the venv.
        bootstrapPython = pkgs.python312;
        cacheRoot = "\${XDG_CACHE_HOME:-$HOME/.cache}/qa-infra";
        venvDir = "${cacheRoot}/venv";
        collectionsPath = "${cacheRoot}/ansible-collections";
      in
        pkgs.mkShell {
          packages = [
            pkgs.opentofu # `tofu` 1.6+
            pkgs.kubernetes-helm # Helm (Rancher deploy)
            pkgs.kubectl
            pkgs.awscli2
            pkgs.git
            bootstrapPython # builds and runs the pinned ansible venv
            # The repo Makefile hardcodes `SHELL := /bin/bash`, which doesn't exist
            # on NixOS. This wrapper forces a real bash via a command-line override
            # (command-line assignment beats the Makefile's SHELL :=).
            (pkgs.writeShellScriptBin "make" ''
              exec ${pkgs.gnumake}/bin/make SHELL=${pkgs.bashInteractive}/bin/bash "$@"
            '')
          ];
          ANSIBLE_HOST_KEY_CHECKING = "False";
          shellHook = ''
            export ANSIBLE_COLLECTIONS_PATH="${collectionsPath}"
            # Build the pinned ansible venv once (outside the repo, idempotent).
            if [ ! -x "${venvDir}/bin/ansible-playbook" ]; then
              echo "[shell] Building pinned ansible venv -> ${venvDir}"
              ${bootstrapPython}/bin/python -m venv "${venvDir}"
              "${venvDir}/bin/pip" install --quiet --upgrade pip
              # ansible-core < 2.19 avoids the json_query data-tagging regression.
              "${venvDir}/bin/pip" install --quiet \
                "ansible-core>=2.18,<2.19" \
                "pyyaml==6.0.2" \
                "jmespath>=1.0.1" \
                "kubernetes>=29.0.0" \
                "boto3>=1.34.0" \
                "botocore>=1.34.0"
            fi
            # Prepend the venv so its ansible* CLIs win over anything else.
            export PATH="${venvDir}/bin:$PATH"
            # Install pinned galaxy collections once (idempotent, outside the repo).
            if [ -f requirements.yml ] && [ ! -d "$ANSIBLE_COLLECTIONS_PATH/ansible_collections/kubernetes" ]; then
              echo "[shell] Installing Ansible collections -> $ANSIBLE_COLLECTIONS_PATH"
              ansible-galaxy collection install -r requirements.yml -p "$ANSIBLE_COLLECTIONS_PATH"
            fi
            echo "qa-infra-automation shell"
            tofu version | head -1
            ansible --version | head -1
            echo "helm $(helm version --short 2>/dev/null)"
          '';
        };
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
