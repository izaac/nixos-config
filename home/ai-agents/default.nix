{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  globalMd = builtins.readFile ./global.md;
  cavemanMd = builtins.readFile ./caveman.md;
  geminiMd = "${config.home.homeDirectory}/.gemini/GEMINI.md";

  cavemanSrc = pkgs.fetchFromGitHub {
    owner = "JuliusBrussee";
    repo = "caveman";
    rev = "754795ada42dea54adf061d42a61e560caa4f9ce";
    hash = "sha256-fT5eFkqZVp1fgwM6iO0d2ER42XaPtLqHlO+TG9cHB74=";
  };

  claudeSkills = [
    "caveman"
    "caveman-commit"
    "caveman-compress"
    "caveman-help"
    "caveman-review"
    "caveman-stats"
    "cavecrew"
  ];
  skillFiles = lib.listToAttrs (map (s: {
      name = ".claude/skills/${s}";
      value = {source = "${cavemanSrc}/skills/${s}";};
    })
    claudeSkills);

  # Own skills, private repo pinned in flake.lock.
  ownSkills = [
    "pw-local-runner"
    "pw-failure-triage"
    "nixos-managing"
    "rancher-qa-plan"
    "rancher-cross-version-perf"
  ];
  ownSkillFiles = lib.listToAttrs (map (s: {
      name = ".claude/skills/${s}";
      value = {source = "${inputs.claude-skills}/skills/${s}";};
    })
    ownSkills);
in {
  home = {
    file =
      skillFiles
      // ownSkillFiles
      // {
        # Claude Code: ~/.claude/CLAUDE.md
        ".claude/CLAUDE.md".text = ''
          ${globalMd}
          ${builtins.readFile ./claude.md}
        '';

        # GitHub Copilot: ~/.copilot/copilot-instructions.md
        ".copilot/copilot-instructions.md".text = ''
          ${cavemanMd}
          ${globalMd}
        '';

        # Gemini CLI: read-only base instructions
        ".gemini/instructions.md".text = ''
          ${cavemanMd}
          ${globalMd}
          ${builtins.readFile ./gemini.md}
        '';

        # Caveman skill default mode
        ".config/caveman/config.json".text = builtins.toJSON {
          defaultMode = "ultra";
        };
      };

    activation = {
      # Ensure ~/.gemini/GEMINI.md exists and pulls in instructions.md. The
      # path keeps its gemini-cli name because Antigravity CLI inherits the
      # same on-disk layout under ~/.gemini/.
      gemini-bootstrap = lib.hm.dag.entryAfter ["writeBoundary"] ''
        if [ ! -f "${geminiMd}" ]; then
          mkdir -p "$(dirname "${geminiMd}")"
          printf '%s\n' '@instructions.md' "" '## Added Memories' > "${geminiMd}"
        elif ! head -1 "${geminiMd}" | grep -q '@instructions.md'; then
          sed -i '1i @instructions.md\n' "${geminiMd}"
        fi
      '';

      # Register MCP servers for AI agents. Antigravity CLI MCP migration is
      # a one-time manual step: `agy plugin import` pulls existing
      # ~/.gemini/settings.json mcpServers entries into agy's mcp_config.json.
      # Versions pinned (no @latest): npx caches the pin and a server bump
      # can't silently change what runs. Bump alongside other updates.
      ai-mcp = lib.hm.dag.entryAfter ["writeBoundary"] ''
        if command -v claude >/dev/null 2>&1; then
          claude mcp add --scope user context7 --transport stdio -- npx -y @upstash/context7-mcp@3.2.0 2>/dev/null || true
          claude mcp add --scope user sequential-thinking --transport stdio -- npx -y @modelcontextprotocol/server-sequential-thinking@2025.12.18 2>/dev/null || true
        fi
      '';
    };
  };
}
