{
  description = "Izaac NVIDIA NixOS and Darwin Configuration";

  inputs = {
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
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
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix.url = "github:danth/stylix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ai-trace-scanner = {
      url = "github:izaac/ai-trace-scanner/v0.8.0";
      flake = false;
    };
    helium.url = "github:FKouhai/helium2nix/main";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    stylix,
    sops-nix,
    darwin,
    ...
  }: let
    systems = ["x86_64-linux" "aarch64-darwin"];
    forEachSystem = nixpkgs.lib.genAttrs systems;
    mkPkgs = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

    userConfig = import ./lib/user.nix;

    mkSystem = import ./lib/mkSystem.nix {
      inherit inputs nixpkgs stylix sops-nix userConfig;
    };

    treefmtEval =
      forEachSystem (system:
        inputs.treefmt-nix.lib.evalModule (mkPkgs system) ./treefmt.nix);
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
            system.stateVersion = "25.11";
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

    darwinConfigurations = {
      Mac = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = {inherit inputs userConfig;};
        modules = [
          ./hosts/Mac/configuration.nix
          inputs.home-manager.darwinModules.home-manager
          inputs.stylix.darwinModules.stylix
          {
            nixpkgs.config.allowUnfree = true;
            nixpkgs.overlays = [
              (import ./overlays/ai-trace-scanner.nix inputs)
            ];
          }
        ];
      };
    };

    packages = forEachSystem (
      system: let
        extraPkgs = inputs.nix-packages.packages.${system} or {};
      in
        extraPkgs
        // (nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          iso = inputs.self.nixosConfigurations.monko-canoe.config.system.build.isoImage;
        })
    );

    formatter =
      forEachSystem (system:
        treefmtEval.${system}.config.build.wrapper);

    devShells = forEachSystem (system: let
      pkgs = mkPkgs system;
    in {
      default = pkgs.mkShell {
        packages =
          [
            treefmtEval.${system}.config.build.wrapper
          ]
          ++ (with pkgs; [
            nixd
            nil
            sops
            ssh-to-age
            age
            git
            just
            nix-init
            nix-melt
            nix-update
            nurl
          ]);
      };
    });

    checks = forEachSystem (system: {
      formatting = treefmtEval.${system}.config.build.check self;
    });
  };
}
