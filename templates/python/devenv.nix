{ pkgs, lib, config, ... }:

{
  # https://devenv.sh/languages/
  languages.python = {
    enable = true;
    # version = "3.12";  # Specify version if needed

    # Use uv for fast package management
    uv.enable = true;

    # Alternative: use venv
    # venv.enable = true;
    # venv.requirements = ./requirements.txt;
  };

  # https://devenv.sh/packages/
  packages = with pkgs; [
    # Python tooling
    # ruff  # Fast linter/formatter (alternative to black/flake8)
    # mypy  # Type checking
    # pytest  # Testing

    # System dependencies (add libraries your project needs)
    # postgresql  # If you need psycopg2
    # stdenv.cc.cc.lib  # For compiled extensions
  ];

  # https://devenv.sh/scripts/
  scripts.test.exec = "pytest";
  scripts.lint.exec = "ruff check .";
  scripts.format.exec = "ruff format .";
  scripts.typecheck.exec = "mypy .";

  # Environment variables
  env = {
    # PYTHONPATH = lib.makeSearchPath "lib/python3.12/site-packages" config.packages;
  };

  enterShell = ''
    echo ""
    echo "Python Development Environment"
    echo "  Python:  $(python --version)"
    echo "  uv:      $(uv --version)"
    echo ""
    echo "Available commands:"
    echo "  test      - Run pytest"
    echo "  lint      - Run ruff linter"
    echo "  format    - Format code with ruff"
    echo "  typecheck - Run mypy type checker"
    echo ""
    echo "Quick start:"
    echo "  uv init         - Initialize new project"
    echo "  uv add <pkg>    - Add a package"
    echo "  uv sync         - Sync dependencies"
    echo "  uv run <cmd>    - Run command in virtual env"
    echo ""
  '';
}
