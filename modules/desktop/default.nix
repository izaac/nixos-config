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

  # Fix for GNOME login freeze / grey screen (3-4 second pause)
  # This explicitly tells xdg-desktop-portal to use the GNOME backend for GNOME sessions,
  # preventing it from timing out while searching for other backends.
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [ 
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = [ "gnome" "gtk" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
      gnome = {
        default = [ "gnome" "gtk" ];
      };
    };
  };

  # Ensure GNOME services are optimized for speed
  services.gnome = {
    gnome-keyring.enable = true;
    gnome-initial-setup.enable = false;
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
