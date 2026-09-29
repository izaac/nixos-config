{userConfig, ...}: {
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
  ];
}
