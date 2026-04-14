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

      # XWayland is provided by cosmic-comp directly — do NOT enable xserver.
      # Enabling it spawns a competing X session on tty1 that blocks greetd's
      # session handoff, preventing cosmic-comp from acquiring DRM master.
      # This caused "Permission denied" on /dev/dri/card1 and cascading
      # COSMIC applet crashes (cosmic-workspaces, xdg-desktop-portal-cosmic, etc).
      xserver.xkb = {
        layout = "us";
        variant = "";
      };
    };

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
