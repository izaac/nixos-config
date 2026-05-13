{modulesPath, ...}: {
  imports = [
    ./base.nix
    (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")
  ];
}
