{userConfig, ...}: {
  programs.ssh = {
    enable = true;

    enableDefaultConfig = false;

    settings = {
      "*" = {
        AddKeysToAgent = "yes";
        IdentityFile = "~/.ssh/id_ed25519";
        # Only offer the configured key, never every key the agent holds — stops
        # leaking unrelated public keys to each host probed.
        IdentitiesOnly = "yes";
        HashKnownHosts = "yes";
        PreferredAuthentications = "publickey,keyboard-interactive,password";
        ServerAliveInterval = 60;
        ServerAliveCountMax = 2;
        StrictHostKeyChecking = "accept-new";
        # Performance & security optimization
        Ciphers = "aes128-gcm@openssh.com,chacha20-poly1305@openssh.com,aes256-gcm@openssh.com";
        MACs = "hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com";
      };
      # GitHub over the FIDO2 security key. The private half lives on the
      # YubiKey, so a push costs one touch (PIN not required, verify-required
      # is deliberately not set). The software key stays for other hosts.
      github = {
        HostName = "github.com";
        User = "git";
        IdentityFile = ["~/.ssh/id_ed25519_sk"];
      };
      # Travel alias: `ssh ninja` / `mosh ninja` / git over SSH.
      # No HostName: Mac resolves via Tailscale MagicDNS on the road and via
      # LAN mDNS at home, both reach the same box without exposing IPs in
      # this repo. ForwardAgent lets ninja authenticate outward (e.g. git
      # push to GitHub) using the local SSH agent during the session.
      ninja = {
        User = userConfig.username;
        ForwardAgent = "yes";
      };
    };
  };
}
