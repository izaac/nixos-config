{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.mySystem.core.nix-ld;
in {
  options.mySystem.core.nix-ld = {
    enable = mkEnableOption "nix-ld support for unpatched binaries";
  };

  config = mkIf cfg.enable {
    programs.nix-ld.enable = true;

    # The "Libraries of Requirement"
    # This list ensures that any binary you download (Node, VSCode extensions, etc.)
    # can find the standard libraries it expects.
    programs.nix-ld.libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      fuse3
      fuse # Legacy FUSE v2 for libfuse.so.2 (Required by many AppImages)
      icu
      nss
      openssl
      curl
      expat
      fontconfig
      freetype
      libGL
      glibc
      libusb1
      glib
      dbus
      pipewire
      alsa-lib
      libpulseaudio
      libX11
      libXcursor
      libXdamage
      libXext
      libXfixes
      libXi
      libXrender
      libXtst
      libxkbcommon
      mesa
      wayland
      libdrm
      libkrb5

      # Cypress / Electron dependencies
      nspr
      atk
      cups
      pango
      cairo
      gtk3
      libxcomposite
      libxrandr
      libxcb
      at-spi2-atk
      at-spi2-core
      libgbm
    ];
  };
}
