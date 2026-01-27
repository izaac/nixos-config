{
  description = "Izaac NVIDIA NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      userConfig = import ./secrets.nix;
      system = "x86_64-linux";
      
      # The "External Instance" that controls everything
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations.ninja = nixpkgs.lib.nixosSystem {
        inherit pkgs; 
        specialArgs = { inherit inputs userConfig; };
        
        modules = [
          ./hosts/ninja/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit userConfig; };
            home-manager.users.${userConfig.username} = import ./home/default.nix;
          }
        ];
      };
    };
}
