{
  description = "Izaac NVIDIA NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-latest.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    catppuccin,
    sops-nix,
    ...
  } @ inputs: let
    userConfig = import ./lib/user.nix;

    # Helper function to generate a host configuration
    mkSystem = import ./lib/mkSystem.nix {
      inherit inputs nixpkgs catppuccin sops-nix userConfig;
    };
  in {
    nixosConfigurations = {
      ninja = mkSystem "ninja" "x86_64-linux";
      windy = mkSystem "windy" "x86_64-linux";
    };
  };
}
