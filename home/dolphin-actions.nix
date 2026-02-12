{ pkgs, ... }:

{
  home.packages = with pkgs; [
    imagemagick # Provides the 'convert' tool
    pngquant    # High-quality lossy PNG compressor
  ];

  # Create the Service Menu for Dolphin
  xdg.dataFile."kio/servicemenus/image-converter.desktop".text = ''
    [Desktop Entry]
    Type=Service
    ServiceTypes=KonqPopupMenu/Plugin
    MimeType=image/*;
    Actions=convertToPng;convertToJpg;convertToWebp;
    X-KDE-Submenu=Convert Image...
    Icon=image-x-generic

    [Desktop Action convertToPng]
    Name=To PNG (Compressed)
    Icon=image-png
    Exec=sh -c "${pkgs.imagemagick}/bin/convert '%f' -strip -depth 8 png:- | ${pkgs.pngquant}/bin/pngquant - > '%n.png'"

    [Desktop Action convertToJpg]
    Name=To JPG
    Icon=image-jpeg
    Exec=${pkgs.imagemagick}/bin/convert %f -strip -quality 90 "%n.jpg"

    [Desktop Action convertToWebp]
    Name=To WEBP
    Icon=image-x-generic
    Exec=${pkgs.imagemagick}/bin/convert %f -strip -quality 90 "%n.webp"
  '';
}
