{ pkgs, ... }:

{
  home.packages = with pkgs; [
    whosthere
  ];

  xdg.configFile."whosthere/config.yaml".text = ''
    theme:
      enabled: true
      name: custom
      primitive_background_color: "#1e1e2e"
      contrast_background_color: "#181825"
      more_contrast_background_color: "#11111b"
      border_color: "#cba6f7"
      title_color: "#89b4fa"
      graphics_color: "#a6e3a1"
      primary_text_color: "#cdd6f4"
      secondary_text_color: "#bac2de"
      tertiary_text_color: "#a6adc8"
      inverse_text_color: "#1e1e2e"
      contrast_secondary_text_color: "#f5c2e7"
  '';
}
