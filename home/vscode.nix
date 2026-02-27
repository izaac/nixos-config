{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode.override {
      commandLineArgs = [
        "--password-store=gnome-libsecret"
        "--ozone-platform=x11"
      ];
    };
  };
}
