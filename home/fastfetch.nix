{pkgs, ...}: {
  home.packages = with pkgs; [
    fastfetch
  ];

  xdg.configFile."fastfetch/config.jsonc".text = ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/master/doc/json_schema.json",
      "modules": [
        "title",
        "separator",
        "os",
        "host",
        "kernel",
        "uptime",
        "packages",
        "shell",
        "display",
        "de",
        "wm",
        "wmtheme",
        "theme",
        "icons",
        "font",
        "cursor",
        "terminal",
        "terminalfont",
        "cpu",
        "gpu",
        {
          "type": "command",
          "key": "NVIDIA Driver",
          "text": "cat /sys/module/nvidia/version"
        },
        "memory",
        "swap",
        "disk",
        "localip",
        "battery",
        "poweradapter",
        "locale",
        "break",
        "colors"
      ]
    }
  '';
}
