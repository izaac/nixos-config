{
  config,
  userConfig,
  ...
}: let
  # ninja runs the ashell stack; windy stays on noctalia until it is migrated.
  # Drop this conditional (and home/noctalia.nix) once both hosts run ashell.
  isNinja = config.networking.hostName == "ninja";
in {
  # This file serves as the "Profile" for the user.
  # It defines all the personal dotfiles and GUI applications that belong to this specific user,
  # completely decoupled from the system-level hardware modules.

  home-manager.users.${userConfig.username}.imports =
    [
      ../../home/desktop.nix
      ../../home/gaming.nix
      ../../home/flatpak.nix
      ../../home/niri.nix
    ]
    ++ (
      if isNinja
      then [
        ../../home/ashell.nix
        ../../home/lock.nix
      ]
      else [../../home/noctalia.nix]
    );
}
