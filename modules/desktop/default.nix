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
  
  # Comprehensive GNOME Debloat
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-initial-setup
    gnome-user-docs
    baobab      # Disk usage analyzer
    epiphany    # Web browser
    geary       # Email client
    totem       # Video player
    yelp        # Help viewer
    evince      # Document viewer (you have PeaZip/Loupe)
    file-roller # Archive manager (you have PeaZip)
    geoclue2    # Location services
    gnome-maps
    gnome-weather
    gnome-contacts
    gnome-music
    gnome-logs
  ];
}
