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
      # Framework-level HM modules shared across all users/hosts.
      # Stylix HM module is imported here (not per-user) so it's
      # available even when the NixOS-level stylix.enable is false.
      sharedModules = [
        inputs.stylix.homeModules.stylix
        inputs.nix-flatpak.homeManagerModules.nix-flatpak
      ];
      extraSpecialArgs = {inherit inputs userConfig;};
      users.${userConfig.username} = {
        imports = [
          ../../home/core.nix
        ];
      };
    };
  };
}
