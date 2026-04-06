{pkgs, ...}: {
  catppuccin.firefox.enable = false;
  catppuccin.firefox.profiles.default.enable = false;

  # We use the standard firefox package here.
  # System-wide policies in hosts/ninja/configuration.nix will apply to this.
  programs.firefox = {
    enable = true;
    package = pkgs.firefox;

    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };
    };
  };

  # Force the desktop entry to use our VIP wrapper.
  # Since policies are now defined at the NixOS system level (/etc/firefox/policies),
  # this wrapper will automatically detect and apply them!
  xdg.desktopEntries.firefox = {
    name = "Firefox";
    genericName = "Web Browser";
    exec = "/run/wrappers/bin/firefox-vip %U";
    terminal = false;
    categories = ["Network" "WebBrowser"];
    mimeType = ["text/html" "text/xml" "application/xhtml+xml" "application/xml" "application/rss+xml" "application/rdf+xml" "image/gif" "image/jpeg" "image/png" "x-scheme-handler/http" "x-scheme-handler/https"];
    icon = "firefox";
  };
}
