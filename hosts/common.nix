# Shared host configuration - imported by ninja/ and windy/
# Each host's configuration.nix should import this and add its deltas.
{lib, ...}: {
  imports = [
    ../modules/core
    ../modules/gaming
    ../modules/desktop
    ../modules/profiles/workstation.nix
    ../users/izaac
  ];

  # Base mySystem structure - hosts override what they need
  mySystem = {
    core = {
      tailscale = {
        enable = lib.mkDefault true;
      };
      virtualization = {
        enable = lib.mkDefault true;
      };
      printing = {
        enable = lib.mkDefault true;
      };
      sops = {
        enable = lib.mkDefault true;
      };
    };
    gaming = {
      sunshine = {
        enable = lib.mkDefault false;
      };
    };
  };

  # Common documentation settings
  documentation = {
    enable = true;
    doc.enable = false;
    man.enable = true;
    info.enable = false;
  };

  system.stateVersion = "25.11";
}
