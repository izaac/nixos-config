{
  lib,
  pkgs,
  inputs,
  ...
}: let
  nix-packages = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system} or {};
in {
  imports = [
    ./shell/packages.nix
    ./shell/aliases.nix
    ./shell/functions.nix
    ./shell/init.nix
    ./shell/programs.nix
    ./shell/env.nix
  ];

  home.packages = lib.optionals (nix-packages ? vcrunch) [nix-packages.vcrunch];
}
