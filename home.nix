{ config, pkgs, ... }:

{
  home.username = "izaac";
  home.homeDirectory = "/home/izaac";

  # Match this to your system's stateVersion (25.11)
  home.stateVersion = "25.11"; 

  # Let Home Manager install itself
  programs.home-manager.enable = true;

  # This is where we'll add your "gadgets" and tools
  home.packages = with pkgs; [
    btop      # Better system monitor for your 5070 Ti
    fastfetch # Shows system info + GPU in terminal
    eza       # Modern 'ls' replacement (very clean)
    vscode
    7zip
    unzip
  ];

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "izaac";
        email = "jorge.izaac@gmail.com";
      };
    };
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "*" = {
        identityFile = "~/.ssh/id_ed25519";
      };
    };
  };

  services.ssh-agent.enable = true;
}
