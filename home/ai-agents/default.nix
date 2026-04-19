{
  pkgs,
  lib,
  userConfig,
  ...
}: let
  globalMd = builtins.readFile ./global.md;
  homeDir = if pkgs.stdenv.isDarwin then "/Users/${userConfig.username}" else "/home/${userConfig.username}";
  geminiMd = "${homeDir}/.gemini/GEMINI.md";
in {
  home.file = {
    # Claude Code: ~/.claude/CLAUDE.md
    ".claude/CLAUDE.md".text = ''
      ${globalMd}
      ${builtins.readFile ./claude.md}
    '';

    # Claude Code: ~/.claude/settings.json
    ".claude/settings.json".text = builtins.toJSON {
      env = {
        CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
      };
      model = "opus[1m]";
      enabledPlugins = {
        "frontend-design@claude-plugins-official" = true;
      };
      hooks = {
        PreToolUse = [
          {
            matcher = "Bash";
            hooks = [
              {
                type = "command";
                "if" = "Bash(git commit)";
                command = "cd \"$CLAUDE_PROJECT_DIR\" && just fmt 2>&1 | tail -5";
                timeout = 60;
              }
              {
                type = "command";
                "if" = "Bash(rm -rf|git push --force|git push -f|git reset --hard|git checkout \\.|git clean -f)";
                command = "echo 'BLOCKED: Destructive command detected. Ask Chief first.' >&2; exit 2";
              }
            ];
          }
          {
            matcher = "Edit|Write";
            hooks = [
              {
                type = "command";
                "if" = "Edit(secrets.yaml|.env|.age|.pem|.key)|Write(secrets.yaml|.env|.age|.pem|.key)";
                command = "echo 'BLOCKED: Cannot write to secret files.' >&2; exit 2";
              }
            ];
          }
        ];
        PostToolUse = [
          {
            matcher = "Edit|Write";
            hooks = [
              {
                type = "command";
                command = "f=\"$CLAUDE_FILE_PATH\"; if [ \"$${f##*.}\" = 'nix' ] && command -v alejandra >/dev/null 2>&1; then alejandra -q \"$f\" 2>/dev/null; fi";
                timeout = 15;
              }
            ];
          }
        ];
      };
    };

    # GitHub Copilot: ~/.copilot/copilot-instructions.md
    ".copilot/copilot-instructions.md".text = globalMd;

    # Gemini CLI: read-only base instructions
    ".gemini/instructions.md".text = ''
      ${globalMd}
      ${builtins.readFile ./gemini.md}
    '';
  };

  # Ensure GEMINI.md exists and has @instructions.md import.
  home.activation.gemini-bootstrap = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -f "${geminiMd}" ]; then
      mkdir -p "$(dirname "${geminiMd}")"
      printf '%s\n' '@instructions.md' "" '## Gemini Added Memories' > "${geminiMd}"
    elif ! head -1 "${geminiMd}" | grep -q '@instructions.md'; then
      sed -i '1i @instructions.md\n' "${geminiMd}"
    fi
  '';

  # Register MCP servers for AI agents
  home.activation.ai-mcp = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if command -v claude >/dev/null 2>&1; then
      claude mcp add --scope user context7 --transport stdio -- npx -y @upstash/context7-mcp@latest 2>/dev/null || true
      claude mcp add --scope user sequential-thinking --transport stdio -- npx -y @modelcontextprotocol/server-sequential-thinking 2>/dev/null || true
    fi
    if command -v gemini >/dev/null 2>&1; then
      gemini mcp add --scope user context7 npx -- -y @upstash/context7-mcp@latest 2>/dev/null || true
    fi
  '';
}
