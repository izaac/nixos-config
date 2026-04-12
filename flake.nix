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
    ai-trace-scanner = {
      url = "github:izaac/ai-trace-scanner/v0.8.0";
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
      monko-canoe = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ({pkgs, ...}: {
            networking = {
              hostName = "monko-canoe";
              networkmanager.enable = true;
              networkmanager.wifi.backend = "iwd";
            };
            system.stateVersion = "25.05";
            hardware.enableRedistributableFirmware = true;
            users.users.${userConfig.username} = {
              isNormalUser = true;
              extraGroups = ["wheel" "networkmanager"];
            };
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
        ];
      };
    };

    packages = forEachSystem (
      system:
        inputs.nix-packages.packages.${system}
        // {
          iso = inputs.self.nixosConfigurations.monko-canoe.config.system.build.isoImage;
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
          alejandra
          sops
          ssh-to-age
          age
          git
          just
        ];
      };
    });

    checks = forEachSystem (system: let
      pkgs = mkPkgs system;
    in {
      formatting =
        pkgs.runCommand "alejandra-check"
        {
          src = ./.;
          nativeBuildInputs = [pkgs.alejandra];
        } ''
          cd "$src"
          alejandra --check .
          touch "$out"
        '';
      linting =
        pkgs.runCommand "statix-check"
        {
          src = ./.;
          nativeBuildInputs = [pkgs.statix];
        } ''
          cd "$src"
          statix check .
          touch "$out"
        '';
      deadcode =
        pkgs.runCommand "deadnix-check"
        {
          src = ./.;
          nativeBuildInputs = [pkgs.deadnix];
        } ''
          cd "$src"
          deadnix --fail .
          touch "$out"
        '';
    });
  };
}
