_: {
  projectRootFile = "flake.nix";
  settings.global.excludes = [
    "secrets/*.yaml"
  ];
  programs = {
    alejandra.enable = true;
    prettier = {
      enable = true;
      settings = {
        proseWrap = "always";
        printWidth = 100;
        singleQuote = true;
        tabWidth = 2;
      };
    };
    statix.enable = true;
    deadnix.enable = true;
    shfmt = {
      enable = true;
      indent_size = 2;
    };
    taplo.enable = true;
    yamlfmt.enable = true;
  };
  settings.formatter = {
    shfmt = {
      options = ["-ci" "-bn"];
      includes = ["*.sh" "*.bash" "*.envrc" "*.envrc.*" ".githooks/pre-commit"];
    };
    prettier = {
      includes = [
        "*.md"
        "*.yaml"
        "*.yml"
        "*.json"
        "*.jsonc"
      ];
      excludes = ["secrets/*.yaml" "secrets/*.yml"];
    };
    taplo = {
      includes = ["*.toml"];
    };
    yamlfmt = {
      includes = ["*.yaml" "*.yml"];
      excludes = ["secrets/*.yaml" "secrets/*.yml"];
    };
  };
}
