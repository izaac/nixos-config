{ pkgs, userConfig, ... }:

{
  # User Account
  users.users.${userConfig.username} = {
    isNormalUser = true;
    description = userConfig.name;
    extraGroups = [ "wheel" "input" "video" "render" "dialout" "podman" "audio" "networkmanager" ];
  };

  # Sudo Configuration
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
    extraConfig = ''
      Defaults editor=${pkgs.vim}/bin/vim
    '';
  };
}
