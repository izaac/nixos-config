{ pkgs, ... }:

{
  # Enable NFS client support
  services.rpcbind.enable = true; # Required for NFSv3

  environment.systemPackages = with pkgs; [
    pkgs.nfs-utils
  ];

  # Kernel modules for NFS support
  boot.supportedFilesystems = [ "nfs" "nfs4" ];
}
