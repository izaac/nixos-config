{
  description = "Ninja - Izaac's NVIDIA NixOS Configuration";

  inputs = {
    # NixOS official package source, using the 25.11 branch
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";

    # Home Manager for user-specific configuration
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      # --- LOAD IDENTITY ---
      # We import the local file. If it doesn't exist, the build fails (safety first).
      userConfig = import ./secrets.nix;
      
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixosConfigurations.ninja = nixpkgs.lib.nixosSystem {
        inherit system;
        
        # Passes variables to configuration.nix and all other modules
        specialArgs = { inherit inputs userConfig; };
        
        modules = [
          # Path to your system configuration
          ./hosts/ninja/configuration.nix

          # Setup Home Manager as a NixOS module
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            
            # Passes variables to home-manager modules (like dev.nix)
            home-manager.extraSpecialArgs = { inherit userConfig; };
            
            # Point to your default home-manager entry point
            home-manager.users.${userConfig.username} = import ./home/default.nix;
          }
        ];
      };
    };
}
