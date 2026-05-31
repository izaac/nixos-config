_: {
  projectRootFile = "flake.nix";
  settings.global.excludes = [
    "secrets/*.yaml"
  ];
  programs = {
    alejandra.enable = true;
    prettier.enable = true;
    statix.enable = true;
    deadnix.enable = true;
    shfmt = {
      enable = true;
      indent_size = 2;
    };
  };
  settings.formatter.shfmt = {
    options = ["-ci" "-bn"];
    includes = ["*.sh" "*.bash" "*.envrc" "*.envrc.*" ".githooks/pre-commit"];
  };
}
