{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.mySystem.core.system;
in {
  options.mySystem.core.system = {
    enable = mkEnableOption "Core system basics (Time, Locales, Nix settings)";
  };

  config = mkIf cfg.enable {
    time.timeZone = "America/Phoenix";
    i18n.defaultLocale = "en_US.UTF-8";

    # Nix Maintenance & Settings
    nix = {
      settings = {
        auto-optimise-store = true;
        experimental-features = ["nix-command" "flakes"];
        trusted-users = ["root" "@wheel"];
        keep-derivations = true;
        keep-outputs = true;
      };
    };

    # Common Services
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = lib.mkDefault false;
        KbdInteractiveAuthentication = lib.mkDefault false;
      };
    };

    services.fstrim.enable = true;
    services.power-profiles-daemon.enable = lib.mkForce false;

    # Limit journal size to prevent unbounded /var/log growth
    services.journald.extraConfig = ''
      SystemMaxUse=500M
      MaxRetentionSec=1month
    '';

    # Auto-purge /tmp files older than 7 days
    systemd.tmpfiles.rules = [
      "q /tmp 1777 root root 7d"
    ];
  };
}
