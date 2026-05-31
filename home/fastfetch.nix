{
  pkgs,
  osConfig,
  ...
}: let
  isDarwin = pkgs.stdenv.isDarwin;

  # Capability detection — derived from actual system config so new hosts
  # inherit the right layout automatically. No hostname hardcoding.
  hasNvidia = osConfig.hardware.nvidia.modesetting.enable or false;
  isLaptop = isDarwin || (osConfig.services.tlp.enable or false);
  hasDataDisk = (osConfig.fileSystems or {}) ? "/mnt/data";
  hasBios = !isDarwin;
  hasGfxApi = !isDarwin; # OpenGL + Vulkan via Linux GBM/DRI stack
  hasBattery = isLaptop;
  hasWifi = isLaptop;
  sym = if isDarwin then "" else "󱄅"; # Apple / NixOS snowflake

  # Gradient + box-drawing constants shared by every section header.
  display = ''
    "display": {
      "separator": " ",
      "constants": [
        "\u001b[38;2;81;188;254m\u001b[1m",
        "\u001b[38;2;105;181;254m\u001b[1m",
        "\u001b[38;2;130;173;253m\u001b[1m",
        "\u001b[38;2;154;166;253m\u001b[1m",
        "\u001b[38;2;169;160;253m\u001b[1m",
        "\u001b[38;2;179;154;253m\u001b[1m",
        "\u001b[38;2;186;153;253m\u001b[1m",
        "\u001b[38;2;192;163;253m\u001b[1m",
        "\u001b[38;2;198;167;253m\u001b[1m",
        "\u001b[38;2;205;173;252m\u001b[1m",
        "┌──────",
        "───────",
        "──────┐"
      ],
      "percent": {
        "type": 9,
        "color": { "green": "#51bcfe", "yellow": "#abff4a", "red": "#ff8f45" }
      }
    },
  '';

  # Hardware section. Items are added conditionally; tree glyphs (├/└) at
  # the boundary (root disk / data disk) shift based on what renders last.
  hardware = ''
    {
      "type": "custom",
      "format": "{$1}{$11}{$2}{$12}{$3}{$12}{$4}{$12}{$5}{$12}{$6}{$12}{$7}{$12}{$8}{$12}{$9}{$12}{$10}{$13} Hardware "
    },
    { "type": "host",    "key": "{$1}├   PC        " },
    { "type": "board",   "key": "{$2}├ 󱔼  Board     " },
    { "type": "cpu",     "key": "{$3}├   CPU       " },
    { "type": "gpu",     "key": "{$4}├ 󰾲  GPU       " },
    ${
      if hasNvidia
      then ''
        {
          "type": "command",
          "key":  "{$4}├   NVIDIA    ",
          "text": "cat /sys/module/nvidia/version 2>/dev/null || echo n/a"
        },
      ''
      else ""
    }
    { "type": "display", "key": "{$5}├ 󰍹  Display   " },
    { "type": "sound",   "key": "{$6}├   Sound     " },
    ${
      if hasBattery
      then ''
        {
          "type": "battery",
          "key": "{$6}├ 󰢟  Battery   ",
          "format": "{manufacturer} {model-name} ({capacity})"
        },
      ''
      else ""
    }
    {
      "type": "memory",
      "key":  "{$7}├   Memory    ",
      "percent": { "type": 3, "green": 30, "yellow": 70 }
    },
    {
      "type": "swap",
      "key":  "{$8}├ 󰯍  Swap      ",
      "percent": { "type": 3, "green": 30, "yellow": 70 }
    },
    {
      "type": "disk",
      "key":  "{$9}${
      if hasDataDisk
      then "├"
      else "└"
    }   ${
      if isDarwin
      then "Root      "
      else "NixOS     "
    }",
      "folders": ["/"],
      "percent": { "type": 3, "green": 30, "yellow": 70 }
    }${
      if hasDataDisk
      then '',
        {
          "type": "disk",
          "key":  "{$10}└   Data      ",
          "folders": ["/mnt/data"],
          "percent": { "type": 3, "green": 30, "yellow": 70 }
        }
      ''
      else ""
    },
  '';

  software = ''
    {
      "type": "custom",
      "format": "{$10}{$11}{$9}{$12}{$8}{$12}{$7}{$12}{$6}{$12}{$5}{$12}{$4}{$12}{$3}{$12}{$2}{$12}{$1}{$13} Software "
    },
    {
      "type": "os",
      "key":  "{$10}├   Distro    ",
      "format": "{name} {build-id} ({codename}) {arch}"
    },
    { "type": "kernel",       "key": "{$10}├   Kernel    " },
    ${
      if hasBios
      then ''{ "type": "bios", "key": "{$9}├ 󰚗  BIOS      " },''
      else ""
    }
    { "type": "packages",     "key": "{$9}├ 󰏖  Packages  " },
    { "type": "shell",        "key": "{$8}├   Shell     " },
    { "type": "terminal",     "key": "{$7}├   Terminal  " },
    { "type": "terminalfont", "key": "{$6}├ 󰛖  Term Font " },
    { "type": "de",           "key": "{$5}├   DE        " },
    { "type": "wm",           "key": "{$3}├   Window    " },
    {
      "type": "wmtheme",
      "key": "{$2}${
      if hasGfxApi
      then "├"
      else "└"
    } 󰉼  Theme     "
    },
    ${
      if hasGfxApi
      then ''
        { "type": "opengl", "key": "{$1}├ 󰆧  OpenGL    " },
        { "type": "vulkan", "key": "{$1}└ 󰈸  Vulkan    " },
      ''
      else ""
    }
  '';

  connectivity = ''
    {
      "type": "custom",
      "format": "{$1}{$11}{$2}{$12}{$3}{$12}{$4}{$12}{$5}{$12}{$6}{$12}{$7}{$12}{$8}{$12}{$9}{$12}{$10}{$13} Connectivity"
    },
    ${
      if hasWifi
      then ''
        {
          "type": "wifi",
          "key":  "{$2}├   WiFi      ",
          "format": "{4} - {7} - {13} GHz - {10}",
          "showErrors": "never"
        },
      ''
      else ""
    }
    { "type": "dns", "key": "{$4}├ 󱦂  DNS       " },
    {
      "type": "localip",
      "key":  "{$6}└ 󰩟  Local IP  ",
      "format": "{1} - {3}",
      "showMac": true
    },
  '';

  time = ''
    {
      "type": "custom",
      "format": "{$10}{$11}{$9}{$12}{$8}{$12}{$7}{$12}{$6}{$12}{$5}{$12}{$4}{$12}{$3}{$12}{$2}{$12}{$1}{$13} Time "
    },
    { "type": "datetime", "key": "{$10}├ 󰥔  Date/Time " },
    {
      "type": "disk",
      "key":  "{$8}├   OS Age    ",
      "folders": "/",
      "format": "{create-time:10} ({days} days)"
    },
    { "type": "uptime", "key": "{$6}└   Uptime    " },
  '';
in {
  home.packages = [pkgs.fastfetch];

  xdg.configFile."fastfetch/config.jsonc".text = ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json",
      "logo": {
        "source": "${
      if isDarwin
      then "macos"
      else "nixos"
    }",
        "padding": { "top": 2, "left": 3 }
      },
      ${display}
      "modules": [
        "break",
        {
          "type": "title",
          "key":  "{$4}                󱐋󱐋 Fastfetch ",
          "format": "{user-name}{$6}@{host-name}"
        },
        ${hardware}
        ${software}
        ${connectivity}
        ${time}
        {
          "type": "custom",
          "format": "                {$10}${sym} {$9}${sym} {$8}${sym} {$7}${sym} {$6}${sym} {$5}${sym} {$4}${sym} {$3}${sym} {$2}${sym} {$1}${sym}"
        }
      ]
    }
  '';
}
