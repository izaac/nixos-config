{
  inputs,
  nixpkgs,
  catppuccin,
  sops-nix,
  userConfig,
}: hostname: system:
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = {
    inherit inputs userConfig;
    latestPkgs = import inputs.nixpkgs-latest {
      inherit system;
      config.allowUnfree = true;
    };
  };

  modules = [
    ../hosts/${hostname}/configuration.nix
    catppuccin.nixosModules.catppuccin
    sops-nix.nixosModules.sops
    ../modules/core/sops.nix
    {
      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [
        (import ../overlays/sparrow-temurin-fix.nix)
        (import ../overlays/dwarfs-fix.nix)
      ];
    }
  ];
}
