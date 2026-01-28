{ pkgs, ... }:

{
  home.packages = [ pkgs.distrobox ];

  # Declarative Distrobox Configuration
  # Run 'distrobox assemble create --file ~/.config/distrobox/distrobox.ini' to build these.
  xdg.configFile."distrobox/distrobox.ini".text = ''
    [arch-box]
    image=archlinux:latest
    pull=true
    additional_packages="git vim neofetch"
    init=false
    nvidia=true
    # Export apps to host automatically
    # export="google-chrome"
    
    [ubuntu-box]
    image=ubuntu:latest
    pull=true
    additional_packages="git curl wget"
    init=false
    nvidia=true
  '';

  # Alias to easily create/update these containers
  programs.bash.shellAliases = {
    db-up = "distrobox assemble create --file ~/.config/distrobox/distrobox.ini";
    db-rm = "distrobox assemble rm --file ~/.config/distrobox/distrobox.ini";
    db-arch = "distrobox enter arch-box";
    db-ubuntu = "distrobox enter ubuntu-box";
  };
}
