{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.mySystem.core.nfs;
in {
  options.mySystem.core.nfs = {
    enable = mkEnableOption "NFS Client support";
  };

  config = mkIf cfg.enable {
    # NFSv4 client support. rpcbind/portmapper is NOT needed — NFSv4 uses
    # port 2049 only and embeds mount/lock/state in the protocol. NixOS's
    # built-in NFS module unconditionally enables rpcbind when any NFS
    # fileSystems entry exists, even for NFSv4-only clients, so we mkForce
    # it off. Re-enable here if a NFSv3 export ever returns.
    services.rpcbind.enable = lib.mkForce false;

    environment.systemPackages = with pkgs; [
      nfs-utils
    ];

    boot.supportedFilesystems = ["nfs4"];
  };
}
