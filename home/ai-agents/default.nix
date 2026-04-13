{
  lib,
  userConfig,
  ...
}: let
  globalMd = builtins.readFile ./global.md;
  geminiMd = "/home/${userConfig.username}/.gemini/GEMINI.md";
in {
  home.file = {
    # Claude Code: ~/.claude/CLAUDE.md
    ".claude/CLAUDE.md".text = ''
      ${globalMd}
      ${builtins.readFile ./claude.md}
    '';

    # Gemini CLI: read-only base instructions
    ".gemini/instructions.md".text = ''
      ${globalMd}
      ${builtins.readFile ./gemini.md}
    '';
  };

  # Bootstrap mutable GEMINI.md that @imports the managed base.
  # Only creates the file if it doesn't exist — preserves memories.
  home.activation.gemini-bootstrap = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -f "${geminiMd}" ]; then
      printf '%s\n' '@instructions.md' "" '## Gemini Added Memories' > "${geminiMd}"
    fi
  '';
}
