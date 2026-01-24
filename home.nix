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
    _7zz
    zip
    unzip
  ];

  programs.bash = {
    enable = true;
    historySize = 10000;
    historyFileSize = 100000;
    historyControl = [ "erasedups" "ignoredups" "ignorespace" ];
  
    # The "Pro" tweaks
    initExtra = ''
      # Append to history instead of overwriting
      shopt -s histappend
      # Save history after every command (don't wait for exit)
      PROMPT_COMMAND="history -a; $PROMPT_COMMAND"
    '';
  };

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
