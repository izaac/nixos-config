{ lib,
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

  home.packages = with pkgs;
    lib.optionals (nix-packages ? vcrunch) [ nix-packages.vcrunch ] ++
    lib.optionals (nix-packages ? brush-shell) [ nix-packages.brush-shell ];
}
