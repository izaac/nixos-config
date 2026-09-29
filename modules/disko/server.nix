# Shared disko pattern for headless servers.
# Takes a disk device path and returns a disko config with ESP + ext4 root (no LUKS).
#
# Usage:
#   imports = [ (import ../../modules/disko/server.nix { device = "/dev/disk/by-id/ata-..."; }) ];
{device}: {
  disko.devices.disk.main = {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          label = "EFI";
          size = "1G";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = ["fmask=0077" "dmask=0077" "noatime"];
          };
        };
        root = {
          label = "root";
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            mountOptions = ["noatime" "nodiratime" "lazytime" "commit=60"];
          };
        };
      };
    };
  };
}
