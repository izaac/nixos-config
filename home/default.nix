{ config, pkgs, userConfig, ... }:

{
  imports = [
    ./shell.nix
    ./distrobox.nix
    ./desktop.nix
    ./firefox.nix
    ./gaming.nix
    ./dev.nix
    ./ssh.nix
    ./sshfs.nix
    ./tmux.nix
    ./kitty.nix
    ./cava.nix
    ./hyprland.nix
    ./waybar.nix
    ./hyprlock.nix
    ./hypridle.nix
  ];

  home.username = userConfig.username;
  home.homeDirectory = "/home/${userConfig.username}";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  services.gnome-keyring = {
    enable = true;
    components = [ "pkcs11" "secrets" "ssh" ];
  };

  home.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";
  };

  # SwayNC Configuration to silence specific notifications (like Bluetooth disconnects)
  xdg.configFile."swaync/config.json".text = builtins.toJSON {
    "$schema" = "${pkgs.swaynotificationcenter}/etc/xdg/swaync/configSchema.json";
    "positionX" = "right";
    "positionY" = "top";
    "layer" = "overlay";
    "control-center-margin-top" = 0;
    "control-center-margin-bottom" = 0;
    "control-center-margin-right" = 0;
    "control-center-margin-left" = 0;
    "notification-icon-size" = 64;
    "notification-body-image-height" = 100;
    "notification-body-image-width" = 200;
    "timeout" = 10;
    "timeout-low" = 5;
    "timeout-critical" = 0;
    "fit-to-screen" = true;
    "control-center-width" = 500;
    "control-center-height" = 600;
    "notification-window-width" = 500;
    "keyboard-shortcuts" = true;
    "image-visibility" = "always";
    "transition-time" = 200;
    "hide-on-clear" = false;
    "hide-on-touch" = true;
    "mouse-waiting-delta" = 200;
    "placeholder-text" = "No Notifications";
    "scripts" = {};
    "notification-visibility" = {
      "blueman" = {
        "state" = "ignored";
        "type" = "app-name";
      };
    };
    "widgets" = [
      "inhibitors"
      "title"
      "dnd"
      "notifications"
    ];
    "widget-config" = {
      "inhibitors" = {
        "text" = "Inhibitors";
        "button-text" = "Clear All";
        "clear-all-button" = true;
      };
      "title" = {
        "text" = "Notifications";
        "clear-all-button" = true;
        "button-text" = "Clear All";
      };
      "dnd" = {
        "text" = "Do Not Disturb";
      };
    };
  };

  services.ssh-agent.enable = false;

}
