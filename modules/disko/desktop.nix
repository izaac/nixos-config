# Shared disko pattern for desktop workstations.
# Takes a disk device path and returns a disko config with ESP + LUKS root.
#
# Usage:
#   imports = [ (import ../../modules/disko/desktop.nix { device = "/dev/disk/by-id/nvme-..."; }) ];
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
        luks = {
          label = "root";
          size = "100%";
          content = {
            type = "luks";
            name = "luks-root";
            settings.allowDiscards = true;
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
  };
}
