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
    # Enable NFS client support
    services.rpcbind.enable = true; # Required for NFSv3

    environment.systemPackages = with pkgs; [
      nfs-utils
    ];

    # Kernel modules for NFS support
    boot.supportedFilesystems = ["nfs" "nfs4"];
  };
}
