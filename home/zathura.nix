# Zathura PDF and Document Viewer configuration.
# Themed automatically by Stylix (stylix.targets.zathura).
_: {
  programs.zathura = {
    enable = true;
    options = {
      selection-clipboard = "clipboard";
      adjust-open = "width";
      pages-per-row = "1";
      scroll-step = "50";

      # Smooth recolor support for dark mode toggle (Ctrl+R)
      recolor = true;
      recolor-keephue = true;
      render-loading = true;
    };
  };
}
