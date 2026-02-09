{ pkgs, userConfig, config, ... }:

{
  environment.systemPackages = with pkgs; [
    pkgs.nh
    pkgs.nvd
    pkgs.nix-output-monitor # Used by nh for the pretty graphs
    kdePackages.partitionmanager
    pkgs.exfatprogs
  ];

  environment.sessionVariables = {
    # Define flake location for nh to avoid typing it explicitly
    # Path sourced from git config in home/dev.nix
    NH_FLAKE = "${userConfig.dotfilesDir}";
  };
}
