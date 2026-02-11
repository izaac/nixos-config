{ pkgs, lib, config, ... }:

{
  # https://devenv.sh/languages/
  languages.javascript = {
    enable = true;
    # package = pkgs.nodejs_22;  # Specify Node version if needed

    # Package manager options
    npm.enable = true;
    pnpm.enable = true;
    yarn.enable = true;
    # bun.enable = true;  # If you want Bun
  };

  # https://devenv.sh/packages/
  packages = with pkgs; [
    # Development tools
    # typescript
    # nodePackages.typescript-language-server
    # nodePackages.eslint
    # nodePackages.prettier

    # Build tools
    # nodePackages.webpack-cli
    # nodePackages.vite
  ];

  # https://devenv.sh/scripts/
  scripts.dev.exec = "npm run dev";
  scripts.build.exec = "npm run build";
  scripts.test.exec = "npm test";
  scripts.lint.exec = "npm run lint";
  scripts.format.exec = "npm run format";

  # Environment variables
  env = {
    # NODE_ENV = "development";
  };

  enterShell = ''
    echo ""
    echo "Node.js Development Environment"
    echo "  Node:    $(node --version)"
    echo "  npm:     $(npm --version)"
    echo "  pnpm:    $(pnpm --version)"
    echo "  yarn:    $(yarn --version)"
    echo ""
    echo "Available commands:"
    echo "  dev     - Run development server"
    echo "  build   - Build for production"
    echo "  test    - Run tests"
    echo "  lint    - Run linter"
    echo "  format  - Format code"
    echo ""
    echo "Quick start:"
    echo "  npm init / pnpm init / yarn init"
    echo "  npm install <pkg> / pnpm add <pkg> / yarn add <pkg>"
    echo ""
  '';
}
