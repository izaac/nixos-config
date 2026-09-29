{...}: {
  imports = [
    ../workstation-common.nix
    ../../modules/profiles/workstation.nix
    ./disko.nix
    ./hardware.nix
    ./ssh.nix
  ];
}
