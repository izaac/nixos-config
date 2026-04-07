{pkgs, ...}: {
  # Smartcard daemon
  services.pcscd.enable = true;

  # Udev rules for YubiKey
  services.udev.packages = with pkgs; [
    yubikey-personalization
  ];

  # Enable U2F for login and sudo
  security.pam.u2f = {
    enable = true;
  };

  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
    # Enable U2F for COSMIC (greetd) login
    cosmic-greeter.u2fAuth = true;
  };

  # YubiKey related packages
  environment.systemPackages = with pkgs; [
    yubikey-manager # ykman CLI
    yubioath-flutter # GUI (replaces yubikey-manager-qt)
    yubikey-personalization # ykpersonalize CLI
    yubico-piv-tool # PIV CLI
    pam_u2f # U2F PAM module
  ];
}
