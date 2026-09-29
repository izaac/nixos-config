# Headless macOS .app for toggling the rclone ul-crypt FUSE mount.
# Double-click or Spotlight "Mount Encrypted Drive" — no terminal window opens,
# just a GUI password prompt (first mount) and a Finder notification.
#
# Requires: macfuse (homebrew cask, declared in hosts/Mac/configuration.nix),
#           rclone with a configured ul-crypt remote (~/.config/rclone/rclone.conf).
{
  pkgs,
  lib,
  ...
}: let
  runtimeDeps = with pkgs; [rclone coreutils];

  rcloneMountToggle = pkgs.writeShellApplication {
    name = "rclone-mount-toggle";
    runtimeInputs = runtimeDeps;
    text = builtins.readFile ./rclone-mount-toggle.sh;
  };

  # Minimal .app bundle so Finder/Spotlight/Dock can launch the toggle
  # without opening a terminal window. LSUIElement keeps it out of the Dock
  # while running.
  rcloneMountApp = pkgs.stdenvNoCC.mkDerivation {
    pname = "rclone-mount-app";
    version = "1.0";
    dontUnpack = true;
    installPhase = ''
      APP="$out/Mount Encrypted Drive.app/Contents"
      mkdir -p "$APP/MacOS"

      cat > "$APP/Info.plist" << 'EOF'
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleExecutable</key>
        <string>rclone-mount-toggle</string>
        <key>CFBundleName</key>
        <string>Mount Encrypted Drive</string>
        <key>CFBundleIdentifier</key>
        <string>com.izaac.rclone-mount</string>
        <key>CFBundleVersion</key>
        <string>1.0</string>
        <key>LSUIElement</key>
        <true/>
      </dict>
      </plist>
      EOF

      cat > "$APP/MacOS/rclone-mount-toggle" << WRAPPER
      #!/bin/bash
      export PATH="${lib.makeBinPath runtimeDeps}:\$PATH"
      exec ${lib.getExe rcloneMountToggle}
      WRAPPER
      chmod +x "$APP/MacOS/rclone-mount-toggle"
    '';
  };
in {
  home.packages = [rcloneMountToggle];

  # Copy the .app into ~/Applications so Spotlight indexes it and it survives
  # GC (nix store symlinks inside .app bundles confuse macOS code signing).
  home.activation.rcloneMountApp = lib.hm.dag.entryAfter ["writeBoundary"] ''
    APP_DEST="$HOME/Applications/Mount Encrypted Drive.app"
    rm -rf "$APP_DEST"
    cp -r "${rcloneMountApp}/Mount Encrypted Drive.app" "$APP_DEST"
  '';
}
