{
  inputs,
  userConfig,
}: hostname: system:
inputs.nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = {
    inherit inputs userConfig;
  };

  # sops wiring lives in modules/core (default.nix -> sops.nix), which every
  # mkSystem host imports — not duplicated here.
  modules = [
    ../hosts/${hostname}/configuration.nix
    inputs.disko.nixosModules.disko
    inputs.stylix.nixosModules.stylix
    inputs.niri-flake.nixosModules.niri
    (import ./common-nixpkgs.nix inputs)
    {
      # Linux-only overlays on top of the shared list.
      nixpkgs.overlays = [
        (import ../overlays/openldap-no-tests.nix)
        (import ../overlays/gvfs-no-wsdd.nix)
        (import ../overlays/dwarfs-skip-affinity-test.nix)
        inputs.niri-flake.overlays.niri
      ];
    }
  ];
}
