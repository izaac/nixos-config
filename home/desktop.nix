{ pkgs, ... }:

{
  # --- FONTS ---
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    # Gnome Tools
    gnome-tweaks
    seahorse
    amberol
    haruna
    firefox
  ];

  # --- GNOME CONFIG ---
  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "dash-to-dock@micxgx.gmail.com"
        "clipboard-indicator@tudmotu.com"
        "caffeine@patapon.info"
        "blur-my-shell@aunetx"
        "vitals@corecoding.com"
        "AlphabeticalAppGrid@stuarthayhurst"
      ];
    };
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "BOTTOM";
      dock-fixed = false;
      dash-max-icon-size = 48;
      background-opacity = 0.8;
    };
    "org/gnome/shell/extensions/vitals" = {
      show-temperature = true;
      show-memory = true;
      show-cpu = true;
    };
  };

  # --- KITTY TERMINAL ---
  programs.kitty = {
    enable = true;
    font.name = "JetBrainsMono Nerd Font Mono";
    
    settings = {
      background_opacity = "0.85";
      window_padding_width = 10;
      enable_audio_bell = false;
      
      # Catppuccin Mocha Theme
      foreground = "#cdd6f4";
      background = "#1e1e2e";
      selection_background = "#f5e0dc";
      selection_foreground = "#1e1e2e";
      
      # The 16 colors (Standard)
      color0 = "#45475a";
      color8 = "#585b70";
      color1 = "#f38ba8";
      color2 = "#a6e3a1";
      color4 = "#89b4fa";
    };
    
    keybindings = {
      "ctrl+shift+t" = "new_tab_with_cwd";
      "ctrl+shift+n" = "new_window_with_cwd";
    };
  };
}
