{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nh
    nvd
    nix-output-monitor # Used by nh for the pretty graphs
  ];

  environment.sessionVariables = {
    # Tell nh where your flake is located so you don't need to type it every time
    # I pulled this path from your git config in home/dev.nix
    NH_FLAKE = "/home/izaac/nixos-config";
  };
}
