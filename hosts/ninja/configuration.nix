{ config, pkgs, inputs, ... }:

{
  imports =
    [ 
      ./hardware.nix
      ./nvidia.nix
      ../../modules/core/nix-ld.nix
      ../../modules/core/codecs.nix
      ../../modules/core/virtualization.nix
      ../../modules/gaming/default.nix
      ../../modules/desktop/default.nix
    ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 5;

  # Networking
  networking.hostName = "ninja";
  networking.networkmanager.enable = true;
  time.timeZone = "America/Phoenix";
  i18n.defaultLocale = "en_US.UTF-8";

  # Audio (Pipewire)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # User Account
  users.users.izaac = {
    isNormalUser = true;
    description = "izaac";
    extraGroups = [ "networkmanager" "wheel" "docker" "input" "video" "libvirtd" "kvm" "render" ];
  };

  # Sudo Config (No Password)
  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
    extraConfig = ''
      Defaults editor=${pkgs.vim}/bin/vim
    '';
  };

  # System Packages (Essentials Only)
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    lact
    swtpm
    file
    libglvnd
  ];
  
  # Services
  services.openssh = {
    enable = true;
    settings = {
      # Hardcore mode: No passwords, keys only.
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  services.fstrim.enable = true;
  services.flatpak.enable = true;

  # Nix Maintenance
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nix.settings.auto-optimise-store = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.11";
}
