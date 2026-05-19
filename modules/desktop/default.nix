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

    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };

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

    # Polkit agent for privileged GUI prompts.
    security.polkit.enable = true;
    systemd.user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = ["graphical-session.target"];
      wants = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };

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
