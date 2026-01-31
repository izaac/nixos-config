{ pkgs, ... }:

{
  # --- HYPRLAND DESKTOP ENVIRONMENT ---
  programs.hyprland.enable = true;

  # XServer is technically required for the DM infrastructure in NixOS
  services.xserver.enable = true;

  # Enable GDM (GNOME Display Manager)
  services.xserver.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  # Ensure GNOME services are optimized for speed (Keyring is vital for Hyprland too)
  services.gnome = {
    gnome-keyring.enable = true;
    gnome-initial-setup.enable = false;
  };

  # Explicitly enable gnome-keyring components for PAM
  security.pam.services.gdm.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;
  services.dbus.packages = [ pkgs.gcr ]; # Ensure GCR is available for prompts

  # Optimized Portal Configuration
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [ 
      pkgs.xdg-desktop-portal-hyprland 
      pkgs.xdg-desktop-portal-gtk 
      pkgs.xdg-desktop-portal-gnome 
    ];
    config = {
      common = {
        default = [ "hyprland" "gtk" ];
        "org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
      };
      hyprland = {
        default = [ "hyprland" "gtk" ];
      };
    };
  };

  # Keyboard Layout
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Services often useful for desktop usage
  services.libinput.enable = true; # Touchpad support

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