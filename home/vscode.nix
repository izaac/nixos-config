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
      "telemetry.telemetryLevel" = "off";
      "redhat.telemetry.enabled" = false;
      "geminicodeassist.enableTelemetry" = false;
      "telemetry.editStats.enabled" = false;
      "telemetry.feedback.enabled" = false;
      "workbench.enableExperiments" = false;
      "update.mode" = "none";
    };
  };
}
