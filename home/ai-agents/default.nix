{
  pkgs,
  lib,
  userConfig,
  ...
}: let
  globalMd = builtins.readFile ./global.md;
  homeDir =
    if pkgs.stdenv.isDarwin
    then "/Users/${userConfig.username}"
    else "/home/${userConfig.username}";
  geminiMd = "${homeDir}/.gemini/GEMINI.md";
in {
  home = {
    file = {
      # Claude Code: ~/.claude/CLAUDE.md
      ".claude/CLAUDE.md".text = ''
        ${globalMd}
        ${builtins.readFile ./claude.md}
      '';

      # GitHub Copilot: ~/.copilot/copilot-instructions.md
      ".copilot/copilot-instructions.md".text = globalMd;

      # Gemini CLI: read-only base instructions
      ".gemini/instructions.md".text = ''
        ${globalMd}
        ${builtins.readFile ./gemini.md}
      '';
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
