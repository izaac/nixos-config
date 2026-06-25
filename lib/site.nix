# Site-wide constants shared by every host on the LAN. Unlike per-host
# settings (hostname, network interface, disko layout) which live under
# hosts/, these describe the network the machines plug into.
{
  # LAN subnet, advertised by the Tailscale subnet router.
  subnet = "192.168.0.0/24";

  # Canon LBP113/LBP913 network laser printer.
  # Pinned to .50 via a Pi-hole DHCP reservation (MAC c4:ac:59:a9:5f:8c),
  # below the dynamic pool (.97-.240) so it never collides with a lease.
  printerIp = "192.168.0.50";
}
