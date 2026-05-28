let
  username = "izaac";
in {
  inherit username;
  email = "izaac.zavaleta@suse.com";
  name = "Izaac Zavaleta";
  gitKey = "0x3183124333AB684C";
  # Repo checkout differs per platform: ~/nixos-config on Linux,
  # ~/repos/nixos-config on the Darwin Mac. Pass pkgs to pick the right one.
  dotfilesDirFor = pkgs:
    if pkgs.stdenv.isDarwin
    then "/Users/${username}/repos/nixos-config"
    else "/home/${username}/nixos-config";
}
