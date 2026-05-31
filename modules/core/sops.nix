{
  config,
  inputs,
  lib,
  userConfig,
  ...
}:
with lib; let
  cfg = config.mySystem.core.sops;
in {
  options.mySystem.core.sops = {
    enable = mkEnableOption "SOPS secrets management";
  };

  imports = [inputs.sops-nix.nixosModules.sops];

  config = mkIf cfg.enable (let
    inherit (config.users.users.${userConfig.username}) home;
  in {
    sops = {
      defaultSopsFile = ../../secrets/common.yaml;
      defaultSopsFormat = "yaml";
      # User age key — for editing secrets on this machine (`sops secrets/…`).
      age.keyFile = "${home}/.config/sops/age/keys.txt";
      # Host SSH key — sops-nix derives the matching age private key at boot,
      # so decryption no longer depends on the user age file existing.
      # Matches the &host_shared recipient in .sops.yaml.
      age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

      secrets = {
        sshHost.owner = userConfig.username;
        geminiProject.owner = userConfig.username;
        cloudCodeProject.owner = userConfig.username;
      };
    };

    # Lock the age master key to 0600 / dir to 0700 every boot. `z` adjusts
    # mode + ownership of an existing path without creating it, so we don't
    # overwrite the key. Catches drift if anything ever loosens the perms.
    systemd.tmpfiles.rules = [
      "z ${home}/.config/sops/age 0700 ${userConfig.username} users -"
      "z ${home}/.config/sops/age/keys.txt 0600 ${userConfig.username} users -"
    ];
  });
}
