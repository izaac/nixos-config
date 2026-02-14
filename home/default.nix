{ config, pkgs, lib, userConfig, ... }:

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
    ./cmus.nix
    ./qt.nix
    ./chromium.nix
    ./lazyvim.nix
    ./theme.nix
    ./mpv.nix
  ];

  home.username = userConfig.username;
  home.homeDirectory = "/home/${userConfig.username}";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  # GNOME Performance & UX Tweaks
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      enable-animations = false;
    };
    "org/gnome/mutter" = {
      edge-tiling = true;
      dynamic-workspaces = true;
      workspaces-only-on-primary = true;
      experimental-features = [ "variable-refresh-rate" ];
    };
    "org/gnome/shell" = {
      disable-user-extensions = false;
    };
    "org/gnome/shell/app-switcher" = {
      current-workspace-only = true;
    };
    "org/gnome/settings-daemon/plugins/power" = {
      sleep-inactive-ac-type = "nothing";
      sleep-inactive-battery-type = "nothing";
      idle-dim = false;
    };
    "org/gnome/desktop/session" = {
      idle-delay = lib.hm.gvariant.mkUint32 0;
    };
    "org/gnome/desktop/screensaver" = {
      lock-enabled = false;
    };
  };

  home.packages = with pkgs; [
    ventoy-full-gtk
  ];


}
