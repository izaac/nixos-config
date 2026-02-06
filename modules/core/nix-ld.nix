{ pkgs, ... }:

{
  programs.nix-ld.enable = true;
  
  # The "Libraries of Requirement"
  # Grouped for easier maintenance and completeness for modern dev tools
  programs.nix-ld.libraries = with pkgs; [
    # --- System & Core ---
    stdenv.cc.cc.lib
    glibc
    libgcc.lib
    zlib
    openssl
    curl
    expat
    libkrb5
    libuuid

    # --- UI & Desktop ---
    dbus
    libsecret
    nss
    nspr
    at-spi2-atk
    at-spi2-core
    libxkbcommon
    pango
    cairo
    gdk-pixbuf
    glib
    gtk3

    # --- Graphics & Media ---
    mesa
    libGL
    libdrm
    wayland
    libusb1
    fuse3
    icu
    libpulseaudio
    alsa-lib
  ];
}
