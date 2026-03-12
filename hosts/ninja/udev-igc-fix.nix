{pkgs, ...}: {
  # Fix for Intel I225-V (igc) networking lockups
  # This uses ethtool to explicitly turn off Energy Efficient Ethernet (EEE)
  # which frequently crashes the I225-V controller under load.
  services.udev.extraRules = ''
    # Fix for Intel I225-V (igc) networking lockups
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="eno1", RUN+="${pkgs.ethtool}/bin/ethtool --set-eee eno1 eee off"

    # Set ASUS USB Audio (0b05:1a52) hardware volume to 100%
    ACTION=="add", SUBSYSTEM=="sound", ATTRS{idVendor}=="0b05", ATTRS{idProduct}=="1a52", RUN+="${pkgs.alsa-utils}/bin/amixer -c %n cset numid=21 87", RUN+="${pkgs.alsa-utils}/bin/amixer -c %n cset numid=28 on"
  '';
}
