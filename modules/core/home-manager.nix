{
  config,
  inputs,
  lib,
  userConfig,
  latestPkgs,
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
      extraSpecialArgs = {inherit inputs userConfig latestPkgs;};
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
