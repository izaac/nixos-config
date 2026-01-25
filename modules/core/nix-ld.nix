{ pkgs, ... }:

{
  programs.nix-ld.enable = true;
  
  # The "Libraries of Requirement"
  # This list ensures that any binary you download (Node, VSCode extensions, etc.) 
  # can find the standard libraries it expects.
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    fuse3
    icu
    nss
    openssl
    curl
    expat
    libGL
    glibc
    libusb1
    glib
    dbus
    libxkbcommon
    mesa
    wayland
    libdrm
    libkrb5
  ];
}
