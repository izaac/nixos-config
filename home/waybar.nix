{ pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    systemd.target = "hyprland-session.target";
    
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        spacing = 4;
        margin-top = 6;
        margin-left = 10;
        margin-right = 10;
        
        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [ "pulseaudio" "network" "cpu" "memory" "tray" "custom/power" ];

        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
          format = "{icon}";
          format-icons = {
            "1" = "";
            "2" = "";
            "3" = "";
            "4" = "";
            "5" = "";
            "urgent" = "";
            "focused" = "";
            "default" = "";
          };
        };

        "hyprland/window" = {
          max-length = 50;
          separate-outputs = true;
        };

        "clock" = {
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
          format-alt = "{:%Y-%m-%d}";
        };

        "cpu" = {
          format = "{usage}% ";
          tooltip = false;
        };

        "memory" = {
          format = "{}% ";
        };

        "network" = {
          format-wifi = "{essid} ({signalStrength}%) ";
          format-ethernet = "{ipaddr}/{cidr} ";
          tooltip-format = "{ifname} via {gwaddr} ";
          format-linked = "{ifname} (No IP) ";
          format-disconnected = "Disconnected ⚠";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
        };

        "pulseaudio" = {
          format = "{volume}% {icon} {format_source}";
          format-bluetooth = "{volume}% {icon} {format_source}";
          format-bluetooth-muted = " {icon} {format_source}";
          format-muted = " {format_source}";
          format-source = "{volume}% ";
          format-source-muted = "";
          format-icons = {
            headphone = "";
            hands-free = "";
            headset = "";
            phone = "";
            portable = "";
            car = "";
            default = [ "" "" "" ];
          };
          on-click = "pavucontrol";
        };
        
        "custom/power" = {
          format = "⏻ ";
          tooltip = false;
          on-click = "wlogout -b 5";
        };
      };
    };

    style = ''
      * {
        border: none;
        font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free", "Font Awesome 6 Brands", "Symbols Nerd Font", sans-serif;
        font-size: 13px;
      }

      window#waybar {
        background-color: transparent;
        color: #cdd6f4;
        transition-property: background-color;
        transition-duration: .5s;
      }

      button {
        box-shadow: inset 0 -3px transparent;
        border: none;
        border-radius: 0;
      }

      button:hover {
        background: inherit;
        box-shadow: inset 0 -3px #ffffff;
      }

      #workspaces {
        background-color: #1e1e2e;
        border-radius: 10px;
        margin-right: 10px;
        padding: 5px;
      }

      #workspaces button {
        padding: 0 5px;
        background-color: transparent;
        color: #cdd6f4;
      }

      #workspaces button:hover {
        background: rgba(0, 0, 0, 0.2);
        color: #f38ba8;
      }

      #workspaces button.active {
        color: #f38ba8;
      }

      #workspaces button.urgent {
        background-color: #eb4d4b;
      }

      #window {
        background-color: #1e1e2e;
        border-radius: 10px;
        padding: 0 10px;
        margin-right: 10px;
      }

      #clock {
        background-color: #1e1e2e;
        border-radius: 10px;
        padding: 0 10px;
      }

      #cpu, #memory, #network, #pulseaudio, #custom-power, #tray {
        background-color: #1e1e2e;
        padding: 0 10px;
        margin-left: 10px;
        border-radius: 10px;
      }

      #custom-power {
        color: #f38ba8;
        padding-right: 15px;
      }
    '';
  };

  # Waybar has a known PulseAudio file descriptor leak that causes it to crash
  # every few minutes when reaching the 1024 limit. Raising the limit mitigates this.
  systemd.user.services.waybar.Service.LimitNOFILE = 1048576;
}