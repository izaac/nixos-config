{
  pkgs,
  lib,
  userConfig,
  ...
}: let
  globalMd = builtins.readFile ./global.md;
  cavemanMd = builtins.readFile ./caveman.md;
  homeDir =
    if pkgs.stdenv.isDarwin
    then "/Users/${userConfig.username}"
    else "/home/${userConfig.username}";
  geminiMd = "${homeDir}/.gemini/GEMINI.md";

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
in {
  home = {
    file =
      skillFiles
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
      # Ensure GEMINI.md exists and has @instructions.md import.
      gemini-bootstrap = lib.hm.dag.entryAfter ["writeBoundary"] ''
        if [ ! -f "${geminiMd}" ]; then
          mkdir -p "$(dirname "${geminiMd}")"
          printf '%s\n' '@instructions.md' "" '## Gemini Added Memories' > "${geminiMd}"
        elif ! head -1 "${geminiMd}" | grep -q '@instructions.md'; then
          sed -i '1i @instructions.md\n' "${geminiMd}"
        fi
      '';

      # Register MCP servers for AI agents
      ai-mcp = lib.hm.dag.entryAfter ["writeBoundary"] ''
        if command -v claude >/dev/null 2>&1; then
          claude mcp add --scope user context7 --transport stdio -- npx -y @upstash/context7-mcp@latest 2>/dev/null || true
          claude mcp add --scope user sequential-thinking --transport stdio -- npx -y @modelcontextprotocol/server-sequential-thinking 2>/dev/null || true
        fi
        if command -v gemini >/dev/null 2>&1; then
          gemini mcp add --scope user context7 npx -- -y @upstash/context7-mcp@latest 2>/dev/null || true
        fi
      '';
    };
  };
}
