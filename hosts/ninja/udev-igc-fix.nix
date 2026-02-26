{ config, pkgs, ... }:

{
  # Fix for Intel I225-V (igc) networking lockups
  # This uses ethtool to explicitly turn off Energy Efficient Ethernet (EEE)
  # which frequently crashes the I225-V controller under load.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="net", KERNEL=="eno1", RUN+="${pkgs.ethtool}/bin/ethtool --set-eee eno1 eee off"
  '';
}
