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
    nix-packages = {
      url = "github:izaac/nix-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ai-trace-scanner = {
      url = "github:izaac/ai-trace-scanner/v0.8.0";
      flake = false;
    };
  };

  outputs = inputs @ {
    nixpkgs,
    catppuccin,
    sops-nix,
    nixos-generators,
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

    packages = forEachSystem (
      system:
        inputs.nix-packages.packages.${system}
        // {
          iso = nixos-generators.outputs.packages.${system}.install-iso.override {
            modules = [
              ({pkgs, ...}: {
                networking.hostName = "monko-canoe";
                hardware.enableRedistributableFirmware = true;
                networking.networkmanager.enable = true;
                networking.networkmanager.wifi.backend = "iwd";
                environment.systemPackages = with pkgs; [
                  helix
                  git
                  neovim
                  usbutils
                  pciutils
                  parted
                  cryptsetup
                ];
              })
              ./users/${userConfig.username}/default.nix
            ];
            format = "install-iso";
          };
        }
    );

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
        pkgs.runCommand "nixpkgs-fmt-check"
        {
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
