{pkgs, ...}: {
  # https://devenv.sh/languages/
  languages.javascript = {
    enable = true;
    # Devenv 2.0: Enable out-of-the-box language server
    lsp.enable = true;
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
  scripts = {
    dev.exec = "npm run dev";
    build.exec = "npm run build";
    test.exec = "npm test";
    lint.exec = "npm run lint";
    format.exec = "npm run format";
  };

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
