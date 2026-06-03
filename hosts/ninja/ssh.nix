{userConfig, ...}: {
  # Key-only sshd. core/system.nix defaults openssh off (mkDefault), so a
  # plain enable here wins without mkForce.
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;
      MaxAuthTries = 3;
      LoginGraceTime = "30s";
    };
  };

  users.users.${userConfig.username}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKReCEJbKJZa0tS2D9owU5+YdXbl1pKpiRBOPlKGbQFh izaac@mac"
  ];

  # Restrict sshd to LAN (eno1) and Tailscale (tailscale0); no WAN exposure.
  networking.firewall.interfaces = {
    eno1.allowedTCPPorts = [22];
    tailscale0.allowedTCPPorts = [22];
  };
}
