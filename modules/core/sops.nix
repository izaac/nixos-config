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
      defaultSopsFile = ../../secrets.yaml;
      defaultSopsFormat = "yaml";
      age.keyFile = "${home}/.config/sops/age/keys.txt";

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
