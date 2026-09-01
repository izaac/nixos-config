{userConfig, ...}: {
  # Key-only sshd. core/system.nix defaults openssh off (mkDefault), so a
  # plain enable here wins without mkForce. windy is a laptop on Wi-Fi
  # (NetworkManager), so the firewall port is opened on all interfaces
  # rather than pinned to a fixed wired interface name.
  services.openssh = {
    enable = true;
    openFirewall = true;
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
    userConfig.sshKeys.ninja
  ];
}
