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
    userConfig.sshKeys.mac
    # ninja's own key, so `ssh ninja` from ninja works. NixOS maps the
    # hostname to 127.0.0.2 by default, so this is a loopback connection that
    # never leaves the box; sshd is not exposed to the WAN either way.
    userConfig.sshKeys.ninja
  ];

  # Restrict sshd to LAN (eno1) and Tailscale (tailscale0); no WAN exposure.
  networking.firewall.interfaces = {
    eno1.allowedTCPPorts = [22];
    tailscale0.allowedTCPPorts = [22];
  };
}
