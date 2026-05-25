{pkgs, ...}: {
  programs.vscode = {
    enable = true;
    package = pkgs.vscode.override {
      commandLineArgs = [
        "--password-store=gnome-libsecret"
      ];
    };
    profiles.default.userSettings = {
      "editor.minimap.enabled" = false;
    };
  };
}
