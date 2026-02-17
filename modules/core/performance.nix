{ pkgs, ... }:

{
  # Ananicy-cpp (Auto-nice daemon)
  # Automatically adjusts process priorities based on rules.
  # This version is a C++ rewrite for much better performance.
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };

  # Irqbalance for better interrupt distribution across cores
  services.irqbalance.enable = true;
}
