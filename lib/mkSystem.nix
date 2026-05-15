{
  inputs,
  userConfig,
}: hostname: system:
inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = {
    inherit inputs userConfig;
  };

  modules = [
    ../hosts/${hostname}/configuration.nix
    inputs.disko.nixosModules.disko
    inputs.stylix.nixosModules.stylix
    inputs.sops-nix.nixosModules.sops
    ../modules/core/sops.nix
    {
      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [
        (import ../overlays/ai-trace-scanner.nix inputs)
        (import ../overlays/cosmic-session-drm-fix.nix)
        (import ../overlays/openldap-no-tests.nix)
        (import ../overlays/gvfs-no-wsdd.nix)
      ];
    }
  ];
}
