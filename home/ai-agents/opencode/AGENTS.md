# OpenCode Global Rules (local-only, not managed by nixos-config)

## Agent cost policy: savings-first

- Always delegate mechanical tasks to the cheapest capable subagent:
  - `explore` (deepseek-v4.1-flash-free): codebase search, file finding, "where is X" questions
  - `general` (deepseek-v4.1-flash-free): bulk multi-step edits from clear patterns
  - `free-assistant` (openrouter/free): quick Q&A, summaries, rewording, formatting
- Keep on the primary model: root-cause analysis, fix design, architecture decisions, anything where
  a wrong-but-confident answer is expensive.
- Launch subagents in background/parallel where possible; keep main context lean.
- Model pins live in `~/.config/opencode/opencode.jsonc`. This directory is local-only: never commit
  it anywhere.

## Git policy

- Never push to a remote unless the user explicitly asks you to in the current turn. "Commit",
  "amend", and "force-push" all require an explicit instruction; do not infer permission from past
  turns.
- Commits and amends to local branches are fine when asked, but the push step is gated on a direct
  request each time.
