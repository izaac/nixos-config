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
    services.desktopManager.cosmic.enable = true;

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };

    # --- DISPLAY MANAGER (cosmic-greeter via greetd) ---
    services.displayManager.cosmic-greeter.enable = true;

    catppuccin.enable = true;
    catppuccin.flavor = "mocha";
    catppuccin.accent = "mauve";
    catppuccin.tty.enable = true;

    security.pam.services.cosmic-greeter.enableGnomeKeyring = true;
    security.pam.services.login.enableGnomeKeyring = true;

    # XServer is required for XWayland
    services.xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };

    # Portals (COSMIC registers its own via the module)
    xdg.portal = {
      enable = true;
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
    };

    # Clipboard manager protocol for COSMIC
    environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = "1";

    environment.systemPackages = with pkgs; [
      adwaita-icon-theme
      libgnome-keyring
      seahorse # GPG/SSH key management
      gcr # Graphical prompts (GPG, etc.)
      pam_gnupg # GPG unlocking
    ];
  };
}
