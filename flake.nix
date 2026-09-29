{
  description = "Izaac NVIDIA NixOS and Darwin Configuration";

  # No nixConfig block: accept-flake-config is off (see modules/core/system.nix),
  # so flake-provided settings would be ignored with a warning anyway. The
  # binary caches are pinned in each host's nix.settings instead.

  inputs = {
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Pinned to an explicit rev, not a branch, so `nix flake update` cannot
    # move it. overlays/patches/ashell-network-backoff.patch rewrites ashell's
    # network service state machine, so it breaks whenever upstream touches
    # that file: 0.10.0 added a field to `State::Active` and broke it already.
    # Floating this input means a routine `just up` can fail the build.
    #
    # This rev ships ashell 0.10.0. To bump ashell deliberately: move the rev,
    # rebuild, and refresh the patch if it no longer applies.
    nixpkgs-ashell.url = "github:nixos/nixpkgs/801bef6abd86b91e51083066b83fb354a11fc640";
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
    claude-skills = {
      # Private repo, fetched over ssh so it stays private. Skill files
      # only, not a flake.
      url = "git+ssh://git@github.com/izaac/claude-skills";
      flake = false;
    };
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
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
    siteConfig = import ./lib/site.nix;

    mkSystem = import ./lib/mkSystem.nix {
      inherit inputs userConfig siteConfig;
    };

    mkDarwin = import ./lib/mkDarwin.nix {
      inherit inputs userConfig siteConfig;
    };

    treefmtEval =
      forEachSystem (system:
        inputs.treefmt-nix.lib.evalModule (mkPkgs system) ./treefmt.nix);

    # Auto-discover hosts: any directory under hosts/ with a system.nix file
    # is automatically added to nixosConfigurations or darwinConfigurations.
    # See docs/adding-a-host.md for the full guide.
    hostDirs =
      nixpkgs.lib.filterAttrs (_name: type: type == "directory")
      (builtins.readDir ./hosts);

    hostSystems =
      nixpkgs.lib.mapAttrs
      (
        name: _:
          import ./hosts/${name}/system.nix
      )
      hostDirs;

    nixosHosts = nixpkgs.lib.filterAttrs (_name: system: system == "x86_64-linux") hostSystems;
    darwinHosts = nixpkgs.lib.filterAttrs (_name: system: system == "aarch64-darwin") hostSystems;

    nixosConfigurations = nixpkgs.lib.mapAttrs (name: _: mkSystem name "x86_64-linux") nixosHosts;
    darwinConfigurations = nixpkgs.lib.mapAttrs (name: _: mkDarwin name) darwinHosts;
  in {
    inherit nixosConfigurations darwinConfigurations;

    packages = forEachSystem (
      system: let
        extraPkgs = inputs.nix-packages.packages.${system} or {};
      in
        # Drop proton-drive-cli: upstream meta only lists x86_64-linux,
        # which breaks `nix flake check` on aarch64-darwin.
        nixpkgs.lib.filterAttrs (name: _: name != "proton-drive-cli") extraPkgs
        // {
          gcroots = import ./lib/gcroots.nix {
            inherit inputs;
            pkgs = mkPkgs system;
          };
        }
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

    checks = forEachSystem (system: let
      pkgs = mkPkgs system;
      mkEvalCheck = name: toplevel:
        pkgs.writeText "${name}-eval-check" (builtins.unsafeDiscardStringContext toplevel.drvPath);

      systemHosts = nixpkgs.lib.filterAttrs (_name: s: s == system) hostSystems;
      configurations =
        if system == "aarch64-darwin"
        then self.darwinConfigurations
        else self.nixosConfigurations;

      hostChecks =
        nixpkgs.lib.mapAttrs
        (
          name: _:
            mkEvalCheck name configurations.${name}.config.system.build.toplevel
        )
        systemHosts;
    in
      hostChecks
      // (nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
        formatting = treefmtEval.${system}.config.build.check self;
      }));
  };
}
