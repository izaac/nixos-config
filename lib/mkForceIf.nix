# Helpers for common lib.mkForce patterns across modules and hosts.
# Usage:
#   specialArgs = { inherit (import ./lib/mkForceIf.nix) mkForceIf mkForceManyIf; };
#   Then in module config: config = { myOption = mkForceIf condition value; };
{lib, ...}: let
  # Apply mkForce only when condition is true, otherwise use normal priority.
  mkForceIf = condition: value:
    lib.mkIf condition (lib.mkForce value) // lib.mkIf (condition == false) value;

  # Apply mkForce to multiple values with same condition.
  mkForceManyIf = condition: values:
    lib.mapAttrs (_n: v: mkForceIf condition v) values;

  # Conditionally enable/disable a service with mkForce.
  # Usage: serviceForceIf condition "serviceName" true/false
  serviceForceIf = condition: name: enabled: {systemd.services.${name}.enable = mkForceIf condition enabled;};

  # Conditionally set kernel parameter with mkForce.
  kernelParamForceIf = condition: param:
    mkForceIf condition param;

  # Conditionally set sysctl with mkForce (returns value directly).
  sysctlForceIf = condition: _name: value: mkForceIf condition value;
in {
  inherit mkForceIf mkForceManyIf serviceForceIf kernelParamForceIf sysctlForceIf;
}
