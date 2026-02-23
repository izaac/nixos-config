{ ... }:
{
  imports = [
    ./user.nix
    ./system.nix
    ./audio.nix
    ./nix-ld.nix
    ./codecs.nix
    ./bluetooth-audio.nix
    ./virtualization.nix
    ./usb-fixes.nix
    ./maintenance.nix
    ./performance.nix
    ./home-manager.nix
  ];
}
