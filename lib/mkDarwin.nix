# Darwin counterpart of mkSystem.nix.
{
  inputs,
  userConfig,
}: hostname:
inputs.darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  specialArgs = {inherit inputs userConfig;};

  modules = [
    ../hosts/${hostname}/configuration.nix
    inputs.home-manager.darwinModules.home-manager
    (import ./common-nixpkgs.nix inputs)
  ];
}
