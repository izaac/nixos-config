# Shared host config for ninja/ and windy. Import in each host's configuration.nix.
{lib, ...}: {
  imports = [
    ../modules/core
    ../users/izaac
  ];

  # Base mySystem with mkDefault for host overrides.
  mySystem = {
    core = {
      tailscale = {
        enable = lib.mkDefault true;
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
