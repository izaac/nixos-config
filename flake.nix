{
  description = "Izaac NVIDIA NixOS and Darwin Configuration";

  # No nixConfig block: accept-flake-config is off (see modules/core/system.nix),
  # so flake-provided settings would be ignored with a warning anyway. The
  # binary caches are pinned in each host's nix.settings instead.

  inputs = {
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-packages = {
      url = "github:izaac/nix-packages";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.treefmt-nix.follows = "treefmt-nix";
    };
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      # Repo moved from LnL7 to the nix-darwin org; release branch must
      # match the nixpkgs release.
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ai-trace-scanner = {
      url = "github:izaac/ai-trace-scanner/v0.8.0";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
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
      inherit inputs userConfig;
    };

    mkDarwin = import ./lib/mkDarwin.nix {
      inherit inputs userConfig;
    };

    treefmtEval =
      forEachSystem (system:
        inputs.treefmt-nix.lib.evalModule (mkPkgs system) ./treefmt.nix);
  in {
    nixosConfigurations = {
      ninja = mkSystem "ninja" "x86_64-linux";
      windy = mkSystem "windy" "x86_64-linux";
      canoe = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs userConfig;};
        modules = [./hosts/canoe/minimal.nix];
      };
      canoe-niri = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs userConfig;};
        modules = [./hosts/canoe/niri.nix];
      };
    };

    darwinConfigurations = {
      Mac = mkDarwin "Mac";
    };

    packages = forEachSystem (
      system: let
        extraPkgs = inputs.nix-packages.packages.${system} or {};
      in
        # Drop proton-drive-cli: upstream meta only lists x86_64-linux,
        # which breaks `nix flake check` on aarch64-darwin.
        nixpkgs.lib.filterAttrs (name: _: name != "proton-drive-cli") extraPkgs
        // (nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          iso = self.nixosConfigurations.canoe.config.system.build.isoImage;
          iso-niri = self.nixosConfigurations.canoe-niri.config.system.build.isoImage;
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
