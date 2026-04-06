{
  description = "Izaac NVIDIA NixOS Configuration";

  inputs = {
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ai-trace-scanner = {
      url = "github:izaac/ai-trace-scanner";
      flake = false;
    };
  };

  outputs = inputs @ {
    nixpkgs,
    catppuccin,
    sops-nix,
    ...
  }: let
    systems = ["x86_64-linux"];
    forEachSystem = nixpkgs.lib.genAttrs systems;
    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

    userConfig = import ./lib/user.nix;

    mkSystem = import ./lib/mkSystem.nix {
      inherit inputs nixpkgs catppuccin sops-nix userConfig;
    };
  in {
    nixosConfigurations = {
      ninja = mkSystem "ninja" "x86_64-linux";
      windy = mkSystem "windy" "x86_64-linux";
    };

    packages = forEachSystem (system: let
      pkgs = mkPkgs system;
    in {
      vcrunch = pkgs.callPackage ./pkgs/vcrunch {};
      zelda-oot = pkgs.callPackage ./pkgs/zelda-oot {};
      default = pkgs.callPackage ./pkgs/vcrunch {};
    });

    devShells = forEachSystem (system: let
      pkgs = mkPkgs system;
    in {
      default = pkgs.mkShell {
        packages = with pkgs; [
          nixd
          nil
          statix
          deadnix
          nixpkgs-fmt
          sops
          ssh-to-age
          age
          git
        ];
      };
    });

    checks = forEachSystem (system: let
      pkgs = mkPkgs system;
    in {
      formatting =
        pkgs.runCommand "nixpkgs-fmt-check" {
          src = ./.;
          nativeBuildInputs = [pkgs.nixpkgs-fmt];
        } ''
          cd "$src"
          nixpkgs-fmt --check .
          touch "$out"
        '';
    });
  };
}
