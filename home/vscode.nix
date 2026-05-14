{pkgs, ...}: {
  programs.vscode = {
    enable = true;
    package = pkgs.vscode.override {
      commandLineArgs = [
        "--password-store=gnome-libsecret"
        "--ozone-platform-hint=auto"
        "--enable-features=WaylandWindowDecorations"
        "--enable-wayland-ime"
      ];
    };
    profiles.default.userSettings = {
      "editor.minimap.enabled" = false;
    };
  };
}
