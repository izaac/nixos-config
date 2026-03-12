{userConfig, ...}: {
  # This file serves as the "Profile" for the user.
  # It defines all the personal dotfiles and GUI applications that belong to this specific user,
  # completely decoupled from the system-level hardware modules.

  home-manager.users.${userConfig.username}.imports = [
    ../../home/desktop.nix
    ../../home/gaming.nix
  ];
}
