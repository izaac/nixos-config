{
  config,
  pkgs,
  lib,
  osConfig ? {},
  ...
}: let
  isWorkstation = (osConfig.mySystem.desktop.enable or false) || pkgs.stdenv.isDarwin;

  # Live-linked to the repo working tree: edits apply with no rebuild.
  # Clone location differs per host: bare dir on Linux, ~/repos on macOS.
  repoDir =
    if pkgs.stdenv.isDarwin
    then "${config.home.homeDirectory}/repos/nixos-config"
    else "${config.home.homeDirectory}/nixos-config";
  opencodeRepoDir = "${repoDir}/home/ai-agents/opencode";
  liveLink = rel: {
    source = config.lib.file.mkOutOfStoreSymlink "${opencodeRepoDir}/${rel}";
  };
in {
  xdg.configFile = lib.optionalAttrs isWorkstation {
    "opencode/opencode.jsonc" = liveLink "opencode.jsonc";
    "opencode/AGENTS.md" = liveLink "AGENTS.md";
    # Generic subagent defs live in the repo; ffta-* stay hand-managed.
    "opencode/agents/free-assistant.md" = liveLink "agents/free-assistant.md";
  };
}
