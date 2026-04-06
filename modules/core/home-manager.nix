{
  config,
  inputs,
  lib,
  userConfig,
  ...
}:
with lib; let
  cfg = config.mySystem.core.home-manager;
in {
  options.mySystem.core.home-manager = {
    enable = mkEnableOption "Home Manager configuration";
  };

  imports = [inputs.home-manager.nixosModules.home-manager];

  config = mkIf cfg.enable {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-backup";
      # Base Home Manager profile:
      # - core.nix: shared CLI/session defaults
      # - catppuccin + nix-flatpak: framework-level HM modules
      # User role/application modules are layered in users/<name>/default.nix
      extraSpecialArgs = {inherit inputs userConfig;};
      users.${userConfig.username} = {
        imports = [
          ../../home/core.nix
          inputs.catppuccin.homeModules.catppuccin
          inputs.nix-flatpak.homeManagerModules.nix-flatpak
        ];
      };
    };
  };
}
