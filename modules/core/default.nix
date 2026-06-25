{...}: {
  imports = [
    ./user.nix
    ./system.nix
    ./audio.nix
    ./nix-ld.nix
    ./codecs.nix
    ./printing.nix
    ./bluetooth.nix
    ./virtualization.nix
    ./usb-fixes.nix
    ./maintenance.nix
    ./performance.nix
    ./home-manager.nix
    ./sops.nix
    ./nfs.nix
    ./yubikey.nix
    ./theme.nix
    ./sudo-readonly.nix
    ./tailscale.nix
    ./known-hosts.nix
  ];
}
