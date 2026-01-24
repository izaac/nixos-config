{
  description = "Izaac NVIDIA NixOS Config";

  inputs = {
    # 1. The main NixOS source (Unstable branch for 50-series support)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # 2. Home Manager (User-level configuration)
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      # This line is critical: it forces HM to use the same packages as your system
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.ninja= nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        # Import your existing system config
        ./configuration.nix

        # Plug in Home Manager as a module
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          
          # This tells HM which user it's managing
          home-manager.users.izaac = import ./home.nix;
        }
      ];
    };
  };
}
