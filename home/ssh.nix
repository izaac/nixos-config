programs.ssh = {
  enable = true;
  addKeysToAgent = "yes";
  
  matchBlocks = {
    "*" = {
      identityFile = "~/.ssh/id_ed25519";
      serverAliveInterval = 60;
      serverAliveCountMax = 2;
    };
  };
};
