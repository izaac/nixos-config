{pkgs, ...}: {
  home.packages = with pkgs; [
    pasystray # Tray applet: switch audio sinks/sources
    networkmanagerapplet # nm-applet + nm-connection-editor
    blueman # blueman-applet + manager
    pavucontrol # PulseAudio volume control (fallback GUI)
    # font-awesome lives in home/desktop.nix
  ];

  programs.waybar = {
    enable = true;

    # Stylix generates the base stylesheet but defines no rule for the
    # custom/power module, so the rightmost glyph sits flush against the
    # screen edge and gets clipped. Append a rule with right padding.
    # style is types.lines, so this concatenates onto Stylix's CSS.
    style = ''
      #custom-power {
        padding: 0 12px 0 5px;
      }
    '';
    # Spawned by niri at session start (see home/niri.nix spawn-at-startup).
    # systemd.enable = true would gate on WAYLAND_DISPLAY, which niri does
    # not import into the systemd user manager early enough, so the unit
    # silently skips with "unmet condition" on every relogin.
    systemd.enable = false;

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
        "battery"
        "cpu"
        "memory"
        "custom/power"
      ];

      "custom/power" = {
        format = "⏻";
        tooltip = false;
        on-click = "wlogout -b 2";
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
