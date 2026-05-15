{
  config,
  lib,
  userConfig,
  ...
}:
with lib; let
  cfg = config.mySystem.core."sudo-readonly";

  bin = "/run/current-system/sw/bin";

  # Read-only diagnostic commands. Each entry maps to an absolute path
  # under /run/current-system/sw/bin (stable across rebuilds).
  readonlyCommands = [
    # Hardware introspection
    "${bin}/lspci"
    "${bin}/lsusb"
    "${bin}/lshw"
    "${bin}/lsblk"
    "${bin}/lsof"
    "${bin}/blkid"
    "${bin}/smartctl"
    "${bin}/nvme"
    "${bin}/dmidecode"

    # Logs and systemd state
    "${bin}/journalctl"
    "${bin}/dmesg"
    "${bin}/systemctl"
    "${bin}/systemd-analyze"
    "${bin}/loginctl"
    "${bin}/udevadm"

    # Boot
    "${bin}/bootctl"

    # Network state (read-only views)
    "${bin}/ss"
    "${bin}/ip"
    "${bin}/nft"

    # Storage state
    "${bin}/cryptsetup"

    # Nix introspection
    "${bin}/nixos-option"
    "${bin}/nix-store"
    "${bin}/nix"

    # I/O profiling
    "${bin}/iotop"
  ];
in {
  options.mySystem.core."sudo-readonly" = {
    enable = mkEnableOption "NOPASSWD sudo for read-only system diagnostics";
  };

  config = mkIf cfg.enable {
    security.sudo-rs.extraRules = [
      {
        users = [userConfig.username];
        commands =
          map (cmd: {
            command = cmd;
            options = ["NOPASSWD" "SETENV"];
          })
          readonlyCommands;
      }
    ];
  };
}
