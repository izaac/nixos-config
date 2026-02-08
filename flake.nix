{
  description = "Izaac NVIDIA NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-small.url = "github:nixos/nixpkgs/nixos-25.11-small";
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixos-unstable, nixos-small, plasma-manager, ... }@inputs:
    let
      userConfig = import ./secrets.nix;
      system = "x86_64-linux";
      pkgs-unstable = import nixos-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      pkgs-small = import nixos-small {
        inherit system;
        config.allowUnfree = true;
      };
    in {
      nixosConfigurations.ninja = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs userConfig; };
        
        modules = [
          ./hosts/ninja/configuration.nix
          home-manager.nixosModules.home-manager
          {
            nixpkgs.config.allowUnfree = true;
            nixpkgs.overlays = [ 
              (import ./overlays/sparrow-temurin-fix.nix)
              (import ./overlays/unstable-packages.nix pkgs-unstable)
              (import ./overlays/small-packages.nix pkgs-small)
            ];
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.extraSpecialArgs = { inherit userConfig; };
            home-manager.users.${userConfig.username} = {
              imports = [ 
                ./home/default.nix
                plasma-manager.homeModules.plasma-manager
              ];
            };
          }
        ];
      };
    };
}
