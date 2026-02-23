{ inputs, userConfig, ... }:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs userConfig; };
    users.${userConfig.username} = {
      imports = [
        ../../home/core.nix
        inputs.catppuccin.homeModules.catppuccin
      ];
    };
  };
}
