{pkgs, ...}: {
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
  ];
}
