{
  pkgs,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    ./base.nix
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-base.nix")
  ];

  isoImage.edition = "cosmic";

  services = {
    # cosmic-comp owns the seat; X server would race on tty1.
    xserver.enable = lib.mkForce false;

    desktopManager.cosmic.enable = true;

    greetd = {
      enable = true;
      settings.initial_session = {
        command = lib.getExe pkgs.cosmic-session;
        user = "nixos";
      };
    };
  };
}
