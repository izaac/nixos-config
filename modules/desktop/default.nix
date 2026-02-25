{ pkgs, lib, userConfig, ... }:

{
  home-manager.users.${userConfig.username}.imports = [ ../../home/desktop.nix ];

  # --- GNOME ---
  services.desktopManager.gnome.enable = true;

  # Performance Tweaks for GNOME
  services.gnome.core-shell.enable = true;
  services.gnome.core-apps.enable = true;
  services.gnome.glib-networking.enable = true;
  services.gnome.evolution-data-server.enable = lib.mkForce false;
  services.gnome.gnome-online-accounts.enable = lib.mkForce false;
  services.gnome.gnome-browser-connector.enable = true;
  services.gnome.gnome-initial-setup.enable = lib.mkForce false;
  services.gnome.gnome-user-share.enable = lib.mkForce false;
  services.gnome.rygel.enable = lib.mkForce false;
  services.gnome.localsearch.enable = false;
  services.gnome.tinysparql.enable = false;

  # Experimental features (VRR, etc.)
  services.desktopManager.gnome.extraGSettingsOverridePackages = [ pkgs.mutter ];
  services.desktopManager.gnome.extraGSettingsOverrides = ''
    [org.gnome.mutter]
    experimental-features=['variable-refresh-rate']
  '';

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
  catppuccin.enable = true;
  catppuccin.flavor = "mocha";
  catppuccin.accent = "mauve";
  catppuccin.tty.enable = true;

  services.displayManager.gdm = {
    enable = true;
    wayland = true;
    autoSuspend = false;
  };
  
  security.pam.services.gdm.enableGnomeKeyring = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # XServer is required for GDM and XWayland
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

  # Remove Bloat
  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
    gnome-contacts
    gnome-maps
    gnome-music
    gnome-weather
    gnome-software
    geary
    epiphany
    rhythmbox
    totem
    tali
    iagno
    hitori
    atomix
    sushi
  ]);

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
    gnome-shell-extensions
    libgnome-keyring # For compatibility with older applications
    seahorse # For managing GPG keys and SSH keys in Gnome Keyring
    gcr # Required for graphical prompts (GPG, etc.)
    pam_gnupg # Required for GPG unlocking
  ];
}
