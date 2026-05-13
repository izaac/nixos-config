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

  # cosmic-comp owns the seat; X server would race on tty1.
  services.xserver.enable = lib.mkForce false;

  services.desktopManager.cosmic.enable = true;

  services.greetd = {
    enable = true;
    settings.initial_session = {
      command = lib.getExe pkgs.cosmic-session;
      user = "nixos";
    };
  };
}
