{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.mySystem.desktop;
in {
  imports = [./nvidia.nix];

  options.mySystem.desktop = {
    enable = mkEnableOption "Desktop Environment configuration";
  };

  config = mkIf cfg.enable {
    # --- Niri (scrollable-tiling Wayland compositor) ---
    # nixosModules.niri enables programs.niri, sets the binary cache,
    # wires the overlay, and auto-imports the home-manager + stylix HM modules.
    programs.niri = {
      enable = true;
      # Unstable required for xwayland-satellite integration.
      package = pkgs.niri-unstable;
    };

    # --- Display Manager: tuigreet on greetd ---
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = builtins.concatStringsSep " " [
            "${pkgs.tuigreet}/bin/tuigreet"
            "--time"
            "--asterisks"
            "--remember"
            "--remember-user-session"
            "--cmd niri-session"
          ];
          user = "greeter";
        };
      };
    };

    # Ensure pam_systemd registers the greeter session as type 'wayland'.
    systemd.services.greetd.environment.XDG_SESSION_TYPE = "wayland";

    # Do NOT enable xserver — niri runs Wayland natively; xwayland-satellite
    # is launched per-user from home/niri.nix for X11 app compatibility.

    # GPG agent is owned by home-manager (services.gpg-agent in home/dev.nix);
    # do not also declare programs.gnupg.agent here or two managers fight over
    # the same socket. SSH auth is owned by gnome-keyring (below), matching
    # home-manager's services.gpg-agent.enableSshSupport = false.

    # Cross-platform LAN file transfer (auto-opens firewall port 53317).
    programs.localsend.enable = true;

    # Auto-mount removable media (USB drives, optical) for udiskie + Nemo.
    services.udisks2.enable = true;

    security.pam.services = {
      greetd.enableGnomeKeyring = true;
      login.enableGnomeKeyring = true;
      swaylock = {};
    };

    # Portals — niri's nixos module enables xdg-desktop-portal-gnome.
    # Chromium/Brave/Electron file dialogs need the GTK portal; add it
    # explicitly and prefer it for the FileChooser interface.
    xdg.portal = {
      extraPortals = [pkgs.xdg-desktop-portal-gtk];
      config.common = {
        default = ["gnome" "gtk"];
        "org.freedesktop.impl.portal.FileChooser" = ["gtk"];
      };
    };

    # Polkit agent for privileged GUI prompts. niri-flake auto-spawns a KDE
    # polkit agent which races ours and loses every login; mask it so only
    # the GNOME agent runs (via XDG autostart from polkit_gnome package).
    security.polkit.enable = true;
    systemd.user.services.niri-flake-polkit.enable = lib.mkForce false;

    environment = {
      gnome.excludePackages = with pkgs; [
        nautilus
        gnome-settings-daemon
        gnome-online-accounts
      ];
      systemPackages = with pkgs; [
        adwaita-icon-theme
        libgnome-keyring
        seahorse # GPG/SSH key management
        gcr # Graphical prompts (GPG, etc.)
        pam_gnupg # GPG unlocking
        polkit_gnome
      ];
    };
  };
}
