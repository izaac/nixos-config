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
    ./qt.nix
    ./chromium.nix
    ./lazyvim.nix
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
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "blur-my-shell@aunetx"
        "just-perfection-desktop@just-perfection"
      ];
    };
    "org/gnome/shell/app-switcher" = {
      current-workspace-only = true;
    };
  };

  home.packages = with pkgs; [
    ventoy-full-gtk
    gnomeExtensions.appindicator
    gnomeExtensions.blur-my-shell
    gnomeExtensions.just-perfection
  ];


}
