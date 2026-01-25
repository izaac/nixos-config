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

  # Clean up XServer options (The "Coolbits" option for Nvidia Overclocking)
  services.xserver.deviceSection = ''
    Option "Coolbits" "28"
  '';
  
  # Exclude default GNOME packages you don't use (Optional debloat)
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
  ];
}
