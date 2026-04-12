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

      # XServer is required for XWayland
      xserver = {
        enable = true;
        xkb = {
          layout = "us";
          variant = "";
        };
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
