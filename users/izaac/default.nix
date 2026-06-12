{userConfig, ...}: {
  # This file serves as the "Profile" for the user.
  # It defines all the personal dotfiles and GUI applications that belong to this specific user,
  # completely decoupled from the system-level hardware modules.

  home-manager.users.${userConfig.username}.imports = [
    ../../home/desktop.nix
    ../../home/gaming.nix
    ../../home/flatpak.nix
    ../../home/niri.nix
    ../../home/waybar.nix
    ../../home/launcher.nix
    ../../home/notifications.nix
    ../../home/screenlock.nix
  ];
}
