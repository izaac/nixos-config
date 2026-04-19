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
      sharedModules = [
        inputs.nix-flatpak.homeManagerModules.nix-flatpak
      ];
      extraSpecialArgs = {inherit inputs userConfig;};
      users.${userConfig.username} = {
        imports = [
          ../../home/core.nix
          ../../home/flatpak.nix
        ];
      };
    };
  };
}
