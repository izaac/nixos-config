_: {
  projectRootFile = "flake.nix";
  settings.global.excludes = [
    "secrets.yaml"
  ];
  programs = {
    alejandra.enable = true;
    prettier.enable = true;
    statix.enable = true;
    deadnix.enable = true;
  };
}
