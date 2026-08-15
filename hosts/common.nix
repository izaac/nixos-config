# Shared host config for ninja/ and windy. Import in each host's configuration.nix.
{lib, ...}: {
  imports = [
    ../modules/core
    ../modules/gaming
    ../modules/desktop
    ../modules/profiles/workstation.nix
    ../users/izaac
  ];

  # Base mySystem with mkDefault for host overrides.
  mySystem = {
    core = {
      tailscale = {
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
