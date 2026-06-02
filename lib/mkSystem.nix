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
    inputs.niri-flake.nixosModules.niri
    ../modules/core/sops.nix
    {
      nixpkgs.config.allowUnfree = true;
      nixpkgs.overlays = [
        inputs.chaotic.overlays.default
        (import ../overlays/ai-trace-scanner.nix inputs)
        (import ../overlays/openldap-no-tests.nix)
        (import ../overlays/gvfs-no-wsdd.nix)
        inputs.niri-flake.overlays.niri
      ];
      # Chaotic-Nyx binary cache (kernel + nvidia served from here)
      nix.settings = {
        substituters = ["https://nyx-cache.chaotic.cx/"];
        trusted-public-keys = ["nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="];
      };
    }
  ];
}
