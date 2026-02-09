{ pkgs, userConfig, config, ... }:

{
  environment.systemPackages = with pkgs; [
    small.nh
    small.nvd
    small.nix-output-monitor # Used by nh for the pretty graphs
    kdePackages.partitionmanager
    small.exfatprogs
  ];

  environment.sessionVariables = {
    # Define flake location for nh to avoid typing it explicitly
    # Path sourced from git config in home/dev.nix
    NH_FLAKE = "${userConfig.dotfilesDir}";
  };
}
