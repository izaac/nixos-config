{ pkgs, lib, config, ... }:

{
  # Hyprland System Settings (via Home Manager)
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;

    # Hyprland configuration translated from dotfiles
    settings = {
      "$mainMod" = "SUPER";
      "$terminal" = "kitty";
      "$filemanager" = "kitty -e yazi";
      "$applauncher" = "fuzzel";
      "$capturing" = "grim -g \"$(slurp)\" - | swappy -f - ";

      monitor = [
        ", preferred, auto, 1"
      ];

      env = [
        "NIXOS_OZONE_WL, 1"
        "__GLX_VENDOR_LIBRARY_NAME, nvidia"
        "LIBVA_DRIVER_NAME, nvidia"
        "XDG_SESSION_TYPE, wayland"
        "XDG_CURRENT_DESKTOP, Hyprland"
        "XDG_SESSION_DESKTOP, Hyprland"
        "QT_QPA_PLATFORM, wayland;xcb"
        "GBM_BACKEND, nvidia-drm"
      ];

      input = {
        kb_layout = "us";
        follow_mouse = 2;
        float_switch_override_focus = 2;
        sensitivity = 0; # -1.0 - 1.0, 0 means no modification.
      };

      general = {
        gaps_in = 3;
        gaps_out = 5;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
      };

      decoration = {
        rounding = 4;
        active_opacity = 1.0;
        inactive_opacity = 0.9;
        
        blur = {
          enabled = true;
          size = 15;
          passes = 2;
          xray = true;
        };

        shadow = {
          enabled = false;
        };
      };

      animations = {
        enabled = true;
        bezier = "overshot, 0.13, 0.99, 0.29, 1.1";
        animation = [
          "windowsIn, 1, 4, overshot, slide"
          "windowsOut, 1, 5, default, popin 80%"
          "border, 1, 5, default"
          "workspacesIn, 1, 6, overshot, slide"
          "workspacesOut, 1, 6, overshot, slidefade 80%"
        ];
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      # Autostart
      exec-once = [
        "waybar"
        "swaync"
        "hyprpaper"
        "hypridle"
        "blueman-applet"
        "jamesdsp --tray"
      ];

      # Keybinds (translated from keybinds.conf)
      bind = [
        "$mainMod, RETURN, exec, $terminal"
        "$mainMod, E, exec, $filemanager"
        "$mainMod, A, exec, $capturing"
        "$mainMod, Q, killactive"
        "$mainMod SHIFT, M, exec, loginctl terminate-user \"\""
        "$mainMod, V, togglefloating"
        "$mainMod, SPACE, exec, $applauncher"
        "$mainMod, F, fullscreen, 0"
        "$mainMod, Y, pin"
        "$mainMod, J, togglesplit"
        "$mainMod, K, togglegroup"
        "$mainMod, Tab, changegroupactive, f"
        
        # Gaps
        "$mainMod SHIFT, G, exec, hyprctl --batch \"keyword general:gaps_out 5;keyword general:gaps_in 3\""
        "$mainMod, G, exec, hyprctl --batch \"keyword general:gaps_out 0;keyword general:gaps_in 0\""

        # Waybar
        "$mainMod, O, exec, killall -SIGUSR2 waybar"
        "$mainMod SHIFT, W, exec, killall waybar || waybar"

        # Focus
        "$mainMod, left, movefocus, l"
        "$mainMod, right, movefocus, r"
        "$mainMod, up, movefocus, u"
        "$mainMod, down, movefocus, d"

        # Move
        "$mainMod SHIFT, left, movewindow, l"
        "$mainMod SHIFT, right, movewindow, r"
        "$mainMod SHIFT, up, movewindow, u"
        "$mainMod SHIFT, down, movewindow, d"

        # Workspaces
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"
        "$mainMod, 6, workspace, 6"
        "$mainMod, 7, workspace, 7"
        "$mainMod, 8, workspace, 8"
        "$mainMod, 9, workspace, 9"
        "$mainMod, 0, workspace, 10"

        # Workspace Navigation
        "$mainMod, PERIOD, workspace, e+1"
        "$mainMod, COMMA, workspace, e-1"
        "$mainMod, slash, workspace, previous"

        # Special Workspaces
        "$mainMod, minus, movetoworkspace, special"
        "$mainMod, equal, togglespecialworkspace, special"
        "$mainMod, F1, togglespecialworkspace, scratchpad"
      ];

      # Mouse Binds
      bindm = [
        "$mainMod, mouse:272, movewindow"
        "$mainMod, mouse:273, resizewindow"
      ];

      # Repeated/Long Press
      bindel = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86MonBrightnessUp, exec, brightnessctl s 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl s 5%-"
      ];

      # Window Rules
      windowrulev2 = [
        "idleinhibit fullscreen, class:.*"
        "float, class:^(org.pulseaudio.pavucontrol)$"
        "float, title:^(Picture-in-Picture)$"
        "float, class:^(blueman-manager)$"
        "opacity 0.92 0.92, class:^(thunar)$"
        "opacity 0.95 0.95, class:^(TelegramDesktop)$"
      ];
    };
  };

  # Waybar Config
  programs.waybar = {
    enable = true;
    # We will copy the style/config later or let user manage it
  };

  # Fuzzel Config
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "kitty";
        layer = "overlay";
      };
      colors = {
        background = "1e1e2edd";
        text = "cdd6f4ff";
        match = "f38ba8ff";
        selection = "585b70ff";
        selection-match = "f38ba8ff";
        selection-text = "cdd6f4ff";
        border = "b4befeff";
      };
    };
  };

  home.packages = with pkgs;
    [
    # Hyprland Ecosystem
    swaynotificationcenter
    hyprpaper
    hyprlock
    hypridle
    swappy               # Screenshot editor (used in $capturing)
    
    # Utilities
    cliphist
    grim
    slurp
    blueman
    pavucontrol
    brightnessctl
    playerctl
    
    # Minimalistic Apps
    xfce.thunar
    xfce.mousepad
  ];
}