{
  inputs,
  nixpkgs,
  stylix,
  sops-nix,
  userConfig,
}: hostname: system:
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = {
    inherit inputs userConfig;
  };

  modules = [
    ../hosts/${hostname}/configuration.nix
    inputs.disko.nixosModules.disko
    stylix.nixosModules.stylix
    sops-nix.nixosModules.sops
    ../modules/core/sops.nix
    {
      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [
        (import ../overlays/sparrow-temurin-fix.nix)
        (import ../overlays/dwarfs-fix.nix)
        (import ../overlays/ai-trace-scanner.nix inputs)
        (import ../overlays/copilot-fix.nix)
      ];
    }
  ];
}
