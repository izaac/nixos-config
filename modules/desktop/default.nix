{ pkgs, ... }:

{
  # --- KDE PLASMA 6 ---
  services.desktopManager.plasma6.enable = true;

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
    SSH_ASKPASS_REQUIRE = "prefer";
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
    kdePackages.kate           # Text editor
    kdePackages.dolphin        # File manager
    kdePackages.konsole        # Terminal
    kdePackages.okular         # Document viewer
    kdePackages.kdenlive       # Video Editor (Optional but native)
    kdePackages.kio-fuse       # FUSE interface for KIO
    kdePackages.kio-extras     # Extra protocols for KIO
  ];
}