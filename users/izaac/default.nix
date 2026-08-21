{userConfig, ...}: {
  # User profile for configured user (${userConfig.username}).
  # Desktop GUI modules are conditionally imported only on hosts with desktop.enable = true.

  home-manager.users.${userConfig.username} = {
    osConfig,
    lib,
    ...
  }: {
    imports = lib.optionals (osConfig.mySystem.desktop.enable or false) [
      ../../home/desktop.nix
      ../../home/gaming.nix
      ../../home/flatpak.nix
      ../../home/niri.nix
      ../../home/ashell.nix
      ../../home/lock.nix
    ];
  };
}
