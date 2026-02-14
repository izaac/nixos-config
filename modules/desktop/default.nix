{ pkgs, ... }:

{
  # --- GNOME ---
  services.xserver.desktopManager.gnome.enable = true;

  # --- KDE PLASMA 6 ---
  services.desktopManager.plasma6.enable = false;

  # --- KDE Connect ---
  programs.kdeconnect.enable = false;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };

  # --- DISPLAY MANAGER (GDM) ---
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };
  
  security.pam.services.gdm.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # XServer is required for SDDM and XWayland
  services.xserver = {
    enable = true;
    # Keyboard Layout
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Portals (Essential for Screen Sharing / File Dialogs)
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    config = {
      common.default = [ "gnome" ];
      gnome.default = [ "gnome" ];
    };
  };



  # Essential GNOME Packages
  environment.systemPackages = with pkgs; [
    nautilus
    gnome-screenshot
    gnome-calculator
    evince
    gnome-system-monitor
    gnome-text-editor
    gnome-control-center
    gnome-tweaks
    adwaita-icon-theme
    gnome-themes-extra
    pkgs.gnome-shell-extensions
    libgnome-keyring # For compatibility with older applications
    seahorse # For managing GPG keys and SSH keys in Gnome Keyring
  ];
}
