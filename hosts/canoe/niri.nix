{
  pkgs,
  lib,
  inputs,
  modulesPath,
  ...
}: {
  imports = [
    ./base.nix
    (modulesPath + "/installer/cd-dvd/installation-cd-graphical-base.nix")
    inputs.niri-flake.nixosModules.niri
  ];

  isoImage.edition = "niri";

  # niri-flake's overlay provides niri-stable/niri-unstable packages.
  nixpkgs.overlays = [inputs.niri-flake.overlays.niri];

  # niri is Wayland-native; the graphical-base X server would race on tty1.
  services.xserver.enable = lib.mkForce false;

  programs.niri.enable = true;

  services.greetd = {
    enable = true;
    settings.initial_session = {
      command = "niri-session";
      user = "nixos";
    };
  };

  # niri's built-in default config (no per-user config on the live ISO) binds
  # Mod+T → alacritty and Mod+D → fuzzel; ship both so the session is usable.
  environment.systemPackages = with pkgs; [
    alacritty
    fuzzel
  ];
}
