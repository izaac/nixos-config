# Declarative disk layout for ninja — mirrors hardware.nix
# Not currently wired into the NixOS build (kept for disko reinstall/reference)
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-CT1000T705SSD3_2404E8929D13";
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
                name = "luks-782b8c84-7a71-4244-8a98-c884f7678b96";
                settings.allowDiscards = true;
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                  # IMPORTANT: disko does not set neededForBoot on the root filesystem.
                  # Without fileSystems."/".neededForBoot = true in hardware.nix, the
                  # initrd has no fstab entry and systemd hangs after LUKS decrypt.
                  mountOptions = ["noatime" "nodiratime" "lazytime" "commit=60" "discard"];
                };
              };
            };
          };
        };
      };
      game = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-WD_BLACK_SN850X_4000GB_24032G801549";
        content = {
          type = "gpt";
          partitions = {
            games = {
              label = "primary";
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/mnt/data";
                mountOptions = ["rw" "noatime" "commit=60" "nofail" "lazytime" "exec" "discard"];
              };
            };
          };
        };
      };
    };
  };
}
