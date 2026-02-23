{ inputs, config, userConfig, ... }:

{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  sops = {
    defaultSopsFile = ../../secrets.yaml;
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/izaac/.config/sops/age/keys.txt";
    
    secrets.sshHost = {
      owner = userConfig.username;
    };
    secrets.geminiProject = {
      owner = userConfig.username;
    };
    secrets.cloudCodeProject = {
      owner = userConfig.username;
    };
  };
}
