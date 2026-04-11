{lib, ...}: {
  networking = {
    hostName = "windy";
    networkmanager.enable = true;

    # Enable wireless support via wpa_supplicant.
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

    # The global useDHCP flag is deprecated in favor of network-specific ontions.
    useDHCP = lib.mkDefault true;

    firewall.enable = true;
  };
}
