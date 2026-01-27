{ pkgs, ... }:

{
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Configure keymap
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  
  # Exclude default GNOME packages you don't use (Optional debloat)
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
  ];
}
