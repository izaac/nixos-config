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

  config = mkIf cfg.enable {
    sops = {
      defaultSopsFile = ../../secrets.yaml;
      defaultSopsFormat = "yaml";
      age.keyFile = "${config.users.users.${userConfig.username}.home}/.config/sops/age/keys.txt";

      secrets = {
        sshHost = {
          owner = userConfig.username;
        };
        geminiProject = {
          owner = userConfig.username;
        };
        cloudCodeProject = {
          owner = userConfig.username;
        };
      };
    };
  };
}
