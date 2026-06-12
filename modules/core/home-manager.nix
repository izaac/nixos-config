{
  config,
  inputs,
  lib,
  userConfig,
  ...
}: let
  cfg = config.mySystem.core.home-manager;
in {
  options.mySystem.core.home-manager = {
    enable = lib.mkEnableOption "Home Manager configuration";
  };

  imports = [inputs.home-manager.nixosModules.home-manager];

  config = lib.mkIf cfg.enable {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-backup";
      sharedModules = [
        inputs.nix-flatpak.homeManagerModules.nix-flatpak
      ];
      extraSpecialArgs = {inherit inputs userConfig;};
      # Only the cross-platform base lives here; the desktop/user-specific
      # composition is the user profile's job (users/<name>/default.nix).
      users.${userConfig.username}.imports = [../../home/core.nix];
    };
  };
}
