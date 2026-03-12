{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.mySystem.core.sshfs;
in {
  options.mySystem.core.sshfs = {
    enable = mkEnableOption "SSHFS configurations";
  };

  config = mkIf cfg.enable {
    # Enable user access to FUSE mounts (required for allow_other with SSHFS)
    programs.fuse.userAllowOther = true;
  };
}
