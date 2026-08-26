{userConfig, ...}: {
  # Key-only sshd, matching windy. core/system.nix defaults openssh off
  # (mkDefault), so a plain enable here wins without mkForce.
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
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJVatwgVrpfaElZ8yZjQqx9irakwJ6xdgE14P8nuPaja izaac@ninja"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKReCEJbKJZa0tS2D9owU5+YdXbl1pKpiRBOPlKGbQFh izaac@mac"
  ];
}
