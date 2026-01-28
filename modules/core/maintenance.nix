{ pkgs, userConfig, ... }:

{
  environment.systemPackages = with pkgs; [
    nh
    nvd
    nix-output-monitor # Used by nh for the pretty graphs
    gparted
  ];

  environment.sessionVariables = {
    # Define flake location for nh to avoid typing it explicitly
    # Path sourced from git config in home/dev.nix
    NH_FLAKE = "${userConfig.dotfilesDir}";
  };
}
