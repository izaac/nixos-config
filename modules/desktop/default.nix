{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.mySystem.desktop;
in {
  options.mySystem.desktop = {
    enable = mkEnableOption "Desktop Environment configuration";
  };

  config = mkIf cfg.enable {
    # --- COSMIC Desktop ---
    services = {
      desktopManager.cosmic.enable = true;

      # --- DISPLAY MANAGER (cosmic-greeter via greetd) ---
      displayManager.cosmic-greeter.enable = true;

      # Override greeter command to set cursor theme.
      # Do NOT add XDG_SESSION_TYPE here — greetd creates the PAM session
      # before running this command, so pam_systemd won't see it.
      greetd.settings.default_session.command = lib.mkForce (
        builtins.concatStringsSep " " [
          "${pkgs.coreutils}/bin/env"
          "XCURSOR_THEME=\${XCURSOR_THEME:-Pop}"
          "${pkgs.cosmic-greeter}/bin/cosmic-greeter-start"
        ]
      );

      # Do NOT enable xserver — cosmic-comp provides its own XWayland.
      # Enabling it spawns a competing X session on tty1 that blocks DRM master.
    };

    # Ensure pam_systemd registers the greeter session as type 'wayland'.
    # Must be in the service environment (not the command) so pam_systemd
    # picks it up via getenv() fallback before the command runs.
    systemd.services.greetd.environment.XDG_SESSION_TYPE = "wayland";

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };

    security.pam.services = {
      cosmic-greeter.enableGnomeKeyring = true;
      login.enableGnomeKeyring = true;
    };

    # Portals (COSMIC registers its own via the module)
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
    };

    # Clipboard manager protocol for COSMIC
    environment = {
      gnome.excludePackages = with pkgs; [
        nautilus
        gnome-settings-daemon
        gnome-online-accounts
      ];
      sessionVariables.COSMIC_DATA_CONTROL_ENABLED = "1";
      systemPackages = with pkgs; [
        adwaita-icon-theme
        libgnome-keyring
        seahorse # GPG/SSH key management
        gcr # Graphical prompts (GPG, etc.)
        pam_gnupg # GPG unlocking
      ];
    };
  };
}
