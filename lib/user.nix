let
  username = "izaac";
in {
  inherit username;
  email = "izaac.zavaleta@suse.com";
  name = "Izaac Zavaleta";
  gitKey = "0x3183124333AB684C";
  # Authorized SSH public keys, keyed by the machine holding the private half.
  # Referenced by each host's ssh.nix and by the canoe installer ISO so a
  # rotated key only has to be edited in one place.
  sshKeys = {
    ninja = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJVatwgVrpfaElZ8yZjQqx9irakwJ6xdgE14P8nuPaja izaac@ninja";
    mac = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKReCEJbKJZa0tS2D9owU5+YdXbl1pKpiRBOPlKGbQFh izaac@mac";
  };
  # Repo checkout differs per platform: ~/nixos-config on Linux,
  # ~/repos/nixos-config on the Darwin Mac. Pass pkgs to pick the right one.
  dotfilesDirFor = pkgs:
    if pkgs.stdenv.isDarwin
    then "/Users/${username}/repos/nixos-config"
    else "/home/${username}/nixos-config";
}
