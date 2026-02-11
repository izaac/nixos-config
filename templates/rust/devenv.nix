{ pkgs, lib, config, ... }:

{
  # https://devenv.sh/languages/
  languages.rust = {
    enable = true;
    channel = "stable";  # or "nightly", "beta"

    # Automatically sets up:
    # - rustc, cargo
    # - rust-analyzer
    # - clippy
    # - rustfmt
  };

  # https://devenv.sh/packages/
  packages = with pkgs; [
    cargo-watch      # Auto-rebuild on file changes
    cargo-edit       # cargo add/rm/upgrade commands
    cargo-audit      # Security vulnerability scanner
    cargo-outdated   # Check for outdated dependencies
    bacon            # Background code checker
  ];

  # https://devenv.sh/scripts/
  scripts.build.exec = "cargo build";
  scripts.test.exec = "cargo test";
  scripts.run.exec = "cargo run";
  scripts.watch.exec = "bacon";

  # https://devenv.sh/pre-commit-hooks/
  # Uncomment to enable pre-commit hooks
  # pre-commit.hooks = {
  #   rustfmt.enable = true;
  #   clippy.enable = true;
  # };

  # https://devenv.sh/processes/
  # Uncomment to run processes in background
  # processes.watch.exec = "cargo watch -x check -x test";

  enterShell = ''
    echo ""
    echo "Rust Development Environment"
    echo "  Rust:   $(rustc --version)"
    echo "  Cargo:  $(cargo --version)"
    echo ""
    echo "Available commands:"
    echo "  build  - Build the project"
    echo "  test   - Run tests"
    echo "  run    - Run the project"
    echo "  watch  - Run bacon (background checker)"
    echo ""
  '';
}
