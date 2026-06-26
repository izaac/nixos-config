{
  config,
  pkgs,
  lib,
  userConfig,
  ...
}: let
  cfg = config.mySystem.core.user;
in {
  options.mySystem.core.user = {
    enable = lib.mkEnableOption "User account and groups configuration";
  };

  config = lib.mkIf cfg.enable {
    # User Account
    users.users.${userConfig.username} = {
      isNormalUser = true;
      description = userConfig.name;
      extraGroups = ["wheel" "input" "video" "render" "dialout" "audio" "networkmanager" "gamemode" "uinput"];
      shell = pkgs.zsh;
      linger = true;
    };

    # Enable Zsh system-wide (required for default shell)
    programs.zsh.enable = true;
    programs.bash.enable = true;

    # sudo-rs is enabled via core/system.nix (mkForce).
    # Configure it here for user-facing settings.
    security.sudo-rs = {
      wheelNeedsPassword = true;
      extraConfig = ''
        Defaults editor=${pkgs.neovim}/bin/nvim
      '';
    };
  };
}
