{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    macchina
  ];

  xdg.configFile."macchina/macchina.toml".text = ''
    theme = "nixos"
  '';

  xdg.configFile."macchina/nixos.ascii".text = ''
      \\  \\ //
     ==\\__\\/ //
       //   \\//
    ==//     //==
     //\\___//
    // /\\  \\==
      // \\  \\
  '';

  xdg.configFile."macchina/themes/nixos.toml".text = ''
    [custom_ascii]
    path = "${config.xdg.configHome}/macchina/nixos.ascii"
    color = "Blue"

    [box]
    title = "NixOS"
    border = "rounded"
    visible = true

    [box.inner_margin]
    x = 1
    y = 0

    [randomize]
    key_color = false
    separator_color = false

    [keys]
    host = "Host"
    machine = "Machine"
    kernel = "Kernel"
    distribution = "Distro"
    os = "OS"
    desktop_environment = "DE"
    window_manager = "WM"
    terminal = "Terminal"
    shell = "Shell"
    packages = "Packages"
    uptime = "Uptime"
    memory = "Memory"
    battery = "Battery"

    [palette]
    type = "Light"

    [color]
    key_color = "Blue"
    separator_color = "Cyan"
  '';
}
