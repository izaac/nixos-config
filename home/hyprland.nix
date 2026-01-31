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

      misc = {
        vfr = true;
        vrr = 1;
        animate_manual_resizes = true;
        animate_mouse_windowdragging = true;
        enable_swallow = true;
        swallow_regex = "^(kitty)$";
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
      };

      # Autostart
      exec-once = [
        "waybar"
        "swaync"
        "hyprpaper"
        "blueman-applet"
        "jamesdsp --tray"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      ];

      # Keybinds (translated from keybinds.conf)
      bind = [
        "$mainMod, RETURN, exec, $terminal"
        "$mainMod, E, exec, $filemanager"
        "$mainMod, Q, killactive"
        
        # Screenshots
        ", Print, exec, grim -g \"$(slurp)\" - | swappy -f -"
        "$mainMod, Print, exec, grim - | swappy -f -"
        "ALT, Print, exec, hyprctl -j activewindow | jq -r '\"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\"' | grim -g - - | swappy -f -"

        "$mainMod SHIFT, M, exec, loginctl terminate-user \"\""
        "$mainMod SHIFT, R, exec, systemctl reboot"
        "$mainMod SHIFT, V, togglefloating"
        "$mainMod, V, exec, cliphist list | fuzzel -d | cliphist decode | wl-copy"
        "$mainMod, SPACE, exec, $applauncher"
        "$mainMod, F, fullscreen, 0"
        "$mainMod, Y, pin"
        "$mainMod, J, togglesplit"
        "$mainMod, K, togglegroup"
        "$mainMod, Tab, exec, hyprctl clients | grep \"class: \" | awk '{print $2}' | fuzzel -d | xargs -I {} hyprctl dispatch focuswindow class:^{}$"
        
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

        # Steam Rules
        "float, class:^(steam)$"
        "tile, class:^(steam)$, title:^(Steam)$" # Force main window to tile
        "float, class:^(steam)$, title:^(Friends List)$"
        "float, class:^(steam)$, title:^(Steam - News)$"
        "float, class:^(steam)$, title:^()$" # For empty title popups
        "center, class:^(steam)$"
      ];
    };
  };

  # GTK and Dark Mode Settings
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style.name = "adwaita-dark";
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
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
    wlogout
    polkit_gnome
    swappy               # Screenshot editor (used in $capturing)
    
    # Utilities
    cliphist
    grim
    slurp
    jq
    blueman
    pavucontrol
    brightnessctl
    playerctl
    
    # Minimalistic Apps
    xfce.thunar
        xfce.mousepad
      ];
    
                  # Wlogout Style Overrides
    
                  xdg.configFile."swappy/config".text = ''
    
                    [Default]
    
                    save_dir=$HOME/Pictures/Screenshots
    
                    save_filename_format=screenshot_%Y%m%d_%H%M%S.png
    
                    show_panel=false
    
                    line_size=5
    
                    text_size=20
    
                    text_font=JetBrainsMono Nerd Font
    
                    paint_mode=brush
    
                    early_exit=true
    
                    fill_shape=false
    
                  '';
    
                
    
                  xdg.configFile."wlogout/layout".text = ''
    
                
    
                  {
    
                      "label" : "lock",
    
                      "action" : "hyprlock",
    
                      "text" : "Lock",
    
                      "keybind" : "l"
    
                  }
    
                  {
    
                      "label" : "logout",
    
                      "action" : "hyprctl dispatch exit",
    
                      "text" : "Logout",
    
                      "keybind" : "e"
    
                  }
    
                  {
    
                      "label" : "suspend",
    
                      "action" : "systemctl suspend",
    
                      "text" : "Suspend",
    
                      "keybind" : "u"
    
                  }
    
                  {
    
                      "label" : "reboot",
    
                      "action" : "systemctl reboot",
    
                      "text" : "Reboot",
    
                      "keybind" : "r"
    
                  }
    
                  {
    
                      "label" : "shutdown",
    
                      "action" : "systemctl poweroff",
    
                      "text" : "Shutdown",
    
                      "keybind" : "s"
    
                  }
    
                '';
    
              
    
            
    
          
    
        
            xdg.configFile."wlogout/style.css".text = ''
        * {
            background-image: none;
            font-family: "JetBrainsMono Nerd Font";
        }
    
        window {
            background-color: rgba(30, 30, 46, 0.9);
        }
    
        button {
            color: #cdd6f4;
            background-color: #1e1e2e;
            border: 2px solid #313244;
            border-radius: 20px;
            margin: 10px;
            background-repeat: no-repeat;
            background-position: center;
            background-size: 35%;
        }
    
        button:hover {
            background-color: #313244;
            border-color: #f38ba8;
        }
    
        #lock { background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/lock.png")); }
        #logout { background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png")); }
        #suspend { background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/suspend.png")); }
        #hibernate { background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/hibernate.png")); }
        #shutdown { background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png")); }
        #reboot { background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png")); }
      '';
    }
    