{ pkgs, ... }:

{
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
    autoSuspend = false;
  };
  services.desktopManager.gnome.enable = true;

  # Ensure GNOME services are optimized for speed
  services.gnome = {
    gnome-keyring.enable = true;
    gnome-initial-setup.enable = false;
  };

  # Optimized Portal Configuration to prevent 20s timeouts
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    config.common.default = [ "gnome" "gtk" ];
  };

  # Configure keymap
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  
  # Exclude unused default GNOME packages (Optional debloat)
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-initial-setup
  ];
}
