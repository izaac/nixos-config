{ pkgs, ... }:

{
  # --- HYPRLAND DESKTOP ENVIRONMENT ---
  programs.hyprland.enable = true;

  # XServer is technically required for the DM infrastructure in NixOS
  services.xserver.enable = true;

  # Enable SDDM (Simple Desktop Display Manager) with Wayland support
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sddm-astronaut-theme";
    package = pkgs.kdePackages.sddm; # Use Qt6 version for better Wayland support
    extraPackages = [ pkgs.kdePackages.qtmultimedia ];
  };

  # Install the theme
  environment.systemPackages = [
    pkgs.sddm-astronaut
  ];

  # Note: services.desktopManager.gnome.enable is NOT set, so we get SDDM + Hyprland only.

  # Ensure GNOME services are optimized for speed (Keyring is vital for Hyprland too)
  services.gnome = {
    gnome-keyring.enable = true;
    gnome-initial-setup.enable = false;
  };

  # Optimized Portal Configuration
  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "hyprland";
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