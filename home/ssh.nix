_: {
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
          SetEnv = "TERM=xterm-256color";
          # Performance & Security Optimization
          Ciphers = "aes128-gcm@openssh.com,chacha20-poly1305@openssh.com,aes256-gcm@openssh.com";
          MACs = "hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com";
        };
      };
    };
  };
}
