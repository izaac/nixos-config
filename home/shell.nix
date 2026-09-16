{
  lib,
  pkgs,
  inputs,
  osConfig ? {},
  ...
}: let
  nix-packages = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system} or {};
  isWorkstation = (osConfig.mySystem.desktop.enable or false) || pkgs.stdenv.isDarwin;
in {
  imports = [
    ./shell/packages.nix
    ./shell/aliases.nix
    ./shell/functions.nix
    ./shell/init.nix
    ./shell/programs.nix
    ./shell/env.nix
    ./shell/zsh.nix
  ];

  home.packages = lib.optionals isWorkstation (
    lib.optional (nix-packages ? vcrunch) nix-packages.vcrunch
    ++ lib.optional (nix-packages ? antigravity-cli) nix-packages.antigravity-cli
  );
}
