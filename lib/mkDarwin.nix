# Darwin counterpart of mkSystem.nix.
{
  inputs,
  userConfig,
  siteConfig,
}: hostname:
inputs.darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  specialArgs = {inherit inputs userConfig siteConfig;};

  modules = [
    ../hosts/${hostname}/configuration.nix
    inputs.home-manager.darwinModules.home-manager
    (import ./common-nixpkgs.nix inputs)
    # Darwin-only: krunkit has no other platform.
    {nixpkgs.overlays = [(import ../overlays/krunkit-unstable.nix inputs)];}
  ];
}
