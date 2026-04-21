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
      extraGroups = ["wheel" "input" "video" "render" "dialout" "docker" "audio" "networkmanager" "gamemode"];
      shell = pkgs.bash;
    };

    # Enable Bash system-wide (Required to use as default shell)
    programs.bash.enable = true;

    # sudo-rs is enabled via core/system.nix (mkForce).
    # Configure it here for user-facing settings.
    security.sudo-rs = {
      wheelNeedsPassword = true;
      extraConfig = ''
        Defaults editor=${pkgs.helix}/bin/hx
      '';
    };
  };
}
