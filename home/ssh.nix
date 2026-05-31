_: {
  programs.ssh = {
    enable = true;

    enableDefaultConfig = false;

    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        IdentityFile = "~/.ssh/id_ed25519";
        PreferredAuthentications = "publickey,keyboard-interactive,password";
        ServerAliveInterval = 60;
        ServerAliveCountMax = 2;
        StrictHostKeyChecking = "accept-new";
        # Performance & security optimization
        Ciphers = "aes128-gcm@openssh.com,chacha20-poly1305@openssh.com,aes256-gcm@openssh.com";
        MACs = "hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com";
      };
      # Travel alias: `ssh ninja` / `mosh ninja` / git over SSH.
      # No HostName: Mac resolves via Tailscale MagicDNS on the road and via
      # LAN mDNS at home, both reach the same box without exposing IPs in
      # this repo. ForwardAgent lets ninja authenticate outward (e.g. git
      # push to GitHub) using the local SSH agent during the session.
      ninja = {
        User = "izaac";
        ForwardAgent = "yes";
      };
    };
  };
}
