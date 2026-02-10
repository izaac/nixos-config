{ pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    
    enableDefaultConfig = false;

    matchBlocks = {
      "*" = {
        addKeysToAgent = "yes";
        identityFile = "~/.ssh/id_ed25519";
        serverAliveInterval = 60;
        serverAliveCountMax = 2;
        extraOptions = {
          StrictHostKeyChecking = "accept-new";
        };
      };
    };
  };
}
