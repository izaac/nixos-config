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
    micro     # Simple terminal text editor
  ];

  # Basic Git config for your user
  programs.git = {
    enable = true;
    userName = "izaac";
    userEmail = "jorge.izaac@gmail.com"; # Change this if you like
  };
}
