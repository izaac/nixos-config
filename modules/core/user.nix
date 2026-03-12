{
  config,
  pkgs,
  lib,
  userConfig,
  ...
}:
with lib; let
  cfg = config.mySystem.core.user;
in {
  options.mySystem.core.user = {
    enable = mkEnableOption "User account and groups configuration";
  };

  config = mkIf cfg.enable {
    # User Account
    users.users.${userConfig.username} = {
      isNormalUser = true;
      description = userConfig.name;
      extraGroups = ["wheel" "input" "video" "render" "dialout" "podman" "audio" "networkmanager"];
    };

    # Sudo Configuration
    security.sudo = {
      enable = true;
      wheelNeedsPassword = true;
      extraConfig = ''
        Defaults editor=${pkgs.neovim}/bin/nvim
      '';
    };
  };
}
