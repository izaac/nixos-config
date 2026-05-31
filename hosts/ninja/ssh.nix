{lib, ...}: {
  # Key-only sshd. core/system.nix disables openssh globally, so override here.
  services.openssh = {
    enable = lib.mkForce true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;
    };
  };

  users.users.izaac.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKReCEJbKJZa0tS2D9owU5+YdXbl1pKpiRBOPlKGbQFh izaac@mac"
  ];

  # Restrict sshd to LAN (eno1) and Tailscale (tailscale0); no WAN exposure.
  networking.firewall.interfaces = {
    eno1.allowedTCPPorts = [22];
    tailscale0.allowedTCPPorts = [22];
  };
}
