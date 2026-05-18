{pkgs, ...}: {
  home.packages = with pkgs; [
    pasystray # Tray applet: switch audio sinks/sources
    networkmanagerapplet # nm-applet + nm-connection-editor
    blueman # blueman-applet + manager
    pavucontrol # PulseAudio volume control (fallback GUI)
    font-awesome # Glyphs used in waybar modules
  ];

  programs.waybar = {
    enable = true;
    systemd.enable = true; # Start after graphical-session.target (proper ordering)

    settings.main = {
      layer = "top";
      position = "top";
      height = 36;
      spacing = 6;

      modules-left = ["niri/workspaces" "niri/window"];
      modules-center = ["clock"];
      modules-right = [
        "tray"
        "pulseaudio"
        "network"
        "bluetooth"
        "battery"
        "cpu"
        "memory"
        "custom/power"
      ];

      "custom/power" = {
        format = "⏻";
        tooltip = false;
        on-click = "wlogout";
      };

      "niri/workspaces" = {
        format = "{icon}";
        format-icons = {
          active = "";
          default = "";
          empty = "";
        };
      };

      "niri/window" = {
        format = "{title}";
        max-length = 60;
      };

      clock = {
        format = "{:%a %d %b  %H:%M}";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
      };

      cpu = {
        format = "  {usage}%";
        interval = 5;
      };

      memory = {
        format = "  {used:0.1f}G";
        interval = 5;
      };

      pulseaudio = {
        # Nerd Font Symbols glyphs (always available via JetBrainsMono NF)
        format = "{icon}  {volume}%";
        format-bluetooth = "󰂰 {volume}%";
        format-muted = "󰝟 muted";
        format-icons = {
          headphone = "󰋋";
          hands-free = "󰂑";
          headset = "󰋎";
          phone = "";
          portable = "";
          car = "";
          default = ["" "" "󰕾"];
        };
        on-click = "pavucontrol";
        on-click-right = "pasystray";
        scroll-step = 5;
      };

      network = {
        format-wifi = "  {essid} ({signalStrength}%)";
        format-ethernet = "  {ipaddr}";
        format-disconnected = "  off";
        tooltip-format = "{ifname}: {ipaddr}";
        on-click = "nm-connection-editor";
      };

      bluetooth = {
        format = "  {status}";
        format-connected = "  {device_alias}";
        on-click = "blueman-manager";
      };

      battery = {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{icon} {capacity}%";
        format-charging = "  {capacity}%";
        format-plugged = "  {capacity}%";
        format-icons = ["" "" "" "" ""];
      };

      tray = {
        icon-size = 18;
        spacing = 8;
      };
    };
  };
}
