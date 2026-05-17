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

    # Adopt the 26.11 default early; we don't use ZFS root, so safe.
    boot.zfs.forceImportRoot = false;

    # --- RUST SYSTEM SPIRITS ---
    # mkForce both: NixOS defaults enable C sudo. We replace it with sudo-rs
    # (memory-safe Rust port) globally, so override the default precedence.
    security = {
      sudo.enable = lib.mkForce false;
      sudo-rs.enable = lib.mkForce true;
    };

    # Nix Maintenance & Settings
    nix = {
      optimise.automatic = true;
      settings = {
        experimental-features = ["nix-command" "flakes"];
        trusted-users = ["root" "@wheel"];
        keep-derivations = true;
        keep-outputs = true;
        # Explicitly lock substituters to prevent rogue cache injection
        substituters = [
          "https://cache.nixos.org"
          "https://izaac-nix.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "izaac-nix.cachix.org-1:ff3lZcS/eWO6i3+BXAds6MbSnEzDe2HMWvTY2bcoXDk="
        ];
        # Ensure sandbox is on (default, but explicit)
        sandbox = true;
      };
    };

    # Common Services
    services = {
      # Replace systemd-timesyncd with ntpd-rs (memory-safe Rust NTP daemon).
      # mkForce both because timesyncd is enabled by default upstream.
      ntpd-rs.enable = lib.mkForce true;
      timesyncd.enable = lib.mkForce false;

      openssh.enable = false;

      fstrim.enable = true;
      # Power management is handled by TLP (windy) or scx_lavd (ninja);
      # mkForce off because some desktop modules pull in this daemon by default.
      power-profiles-daemon.enable = lib.mkForce false;

      # Limit journal size to prevent unbounded /var/log growth
      journald.extraConfig = ''
        SystemMaxUse=2G
        MaxRetentionSec=1month
      '';
    };

    # Don't let NTP block graphical.target — time sync can happen after login.
    # mkForce because the upstream service unit attaches to time-sync.target.
    systemd.services.ntpd-rs.wantedBy = lib.mkForce [];

    # Auto-purge /tmp files older than 7 days
    systemd.tmpfiles.rules = [
      "q /tmp 1777 root root 7d"
    ];
  };
}
