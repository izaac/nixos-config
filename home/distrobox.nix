{ pkgs, userConfig, ... }:

{
  home.packages = [ pkgs.distrobox ];

  # Declarative Distrobox Configuration
  # Run 'distrobox assemble create --file ~/.config/distrobox/distrobox.ini' to build these.
  xdg.configFile."distrobox/distrobox.ini".text = ''
    [archy]
    image=archlinux:latest
    pull=true
    additional_packages="git vim neovim ripgrep lsd fastfetch nss alsa-lib atk cups libdrm libxcomposite libxdamage libxext libxfixes libxkbcommon libxrandr mesa pango cairo gtk3"
    init=false
    nvidia=true
    # Export apps to host automatically
    # export="google-chrome"
    
    [debi]
    image=debian:sid
    pull=true
    additional_packages="build-essential git curl wget neovim ripgrep lsd fastfetch"
    init=false
    nvidia=true

    [rhel10]
    image=registry.access.redhat.com/ubi10/ubi:latest
    pull=true
    additional_packages="subscription-manager git vim"
    init=false
    nvidia=true
  '';

  # Alias to easily create/update these containers
  programs.bash.shellAliases = {
    db-up = "distrobox assemble create --file ~/.config/distrobox/distrobox.ini";
    db-rm = "distrobox assemble rm --file ~/.config/distrobox/distrobox.ini";
    db-arch = "distrobox enter archy";
    db-debian = "distrobox enter debi";
    db-rhel = "distrobox enter rhel10";
  };
}