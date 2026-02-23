{
  description = "Izaac NVIDIA NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    catppuccin.url = "github:catppuccin/nix/release-25.11";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nixos-unstable, catppuccin, sops-nix, ... }@inputs:
    let
      userConfig = import ./lib/user.nix;
      
      # Helper function to generate a host configuration
      mkSystem = hostname: system: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs userConfig; };
        
        modules = [
          ./hosts/${hostname}/configuration.nix
          catppuccin.nixosModules.catppuccin
          sops-nix.nixosModules.sops
          ./modules/core/sops.nix
          {
            nixpkgs.config.allowUnfree = true;
            nixpkgs.overlays = [ 
              (import ./overlays/sparrow-temurin-fix.nix)
              # Instantiate unstable dynamically based on the current system
              (import ./overlays/unstable-packages.nix (import nixos-unstable { inherit system; config.allowUnfree = true; }))
            ];
          }
        ];
      };
    in {
      nixosConfigurations = {
        ninja = mkSystem "ninja" "x86_64-linux";
        windy = mkSystem "windy" "x86_64-linux";
      };
    };
}
