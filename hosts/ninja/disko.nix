{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/nvme0n1"; # Monko assume main drive
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["fmask=0077" "dmask=0077" "noatime"];
              };
            };
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "luks-main";
                # Keep UUID for Chief's secret-box
                extraOpenArgs = ["--allow-discards"];
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                  mountOptions = ["noatime" "nodiratime" "lazytime" "commit=60" "discard"];
                };
              };
            };
          };
        };
      };
      game = {
        type = "disk";
        device = "/dev/nvme1n1"; # Monko assume second NVMe for games
        content = {
          type = "gpt";
          partitions = {
            games = {
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
