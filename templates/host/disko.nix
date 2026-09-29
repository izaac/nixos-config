# Replace /dev/disk/by-id/... with the target disk path.
# Find it with: ls -l /dev/disk/by-id/
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/disk/by-id/REPLACE_ME";
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
