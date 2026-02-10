{ pkgs, ... }:

{
  # --- KDE PLASMA 6 ---
  services.desktopManager.plasma6.enable = true;
  environment.plasma6.excludePackages = with pkgs; [
    kdePackages.baloo
    kdePackages.discover
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = false;
    pinentryPackage = pkgs.pinentry-qt; # Assuming Qt for Plasma desktop
  };

  # --- DISPLAY MANAGER (SDDM) ---
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  
  # Auto-unlock KWallet on login
  security.pam.services.sddm.enableKwallet = true;
  security.pam.services.sddm.gnupg.enable = true;

  # XServer is required for SDDM and XWayland
  services.xserver = {
    enable = true;
    # Keyboard Layout
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # SSH Integration (KDE Wallet & Askpass)
  programs.ssh.askPassword = "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
  environment.sessionVariables = {
    SSH_ASKPASS = "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";
  };

  # Essential KDE Packages & Integration
  environment.systemPackages = with pkgs; [
    kdePackages.ksshaskpass
    kdePackages.sddm-kcm       # SDDM Config Module for Plasma Settings
    kdePackages.partitionmanager
    kdePackages.filelight      # Disk usage
    kdePackages.kcalc          # Calculator
    kdePackages.spectacle      # Screenshot tool
    kdePackages.gwenview       # Image viewer
    kdePackages.ark            # Archive manager
    kdePackages.dolphin        # File manager
    kdePackages.dolphin-plugins # Extra context menu options (Git, SVN, etc.)
    kdePackages.konsole        # Terminal
    kdePackages.okular         # Document viewer
    kdePackages.kdenlive       # Video Editor (Optional but native)
    kdePackages.kio-fuse       # FUSE interface for KIO
    kdePackages.kio-extras     # Extra protocols for KIO
    
    # Secret Management (Seahorse Replacement)
    kdePackages.kwalletmanager # Manage KWallet secrets GUI
    kdePackages.kleopatra      # Certificate Manager (GPG/S/MIME)
  ];
}
