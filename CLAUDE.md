# Claude Code Instructions

> Claude-specific config. Core rules live in AGENTS.md.

See @AGENTS.md for Monko identity, Caveman protocol, and agent boundaries.

## Project Context

- @README.md
- @docs/hardware.md
- @docs/windy.md
- @docs/just-commands.md

## Claude-Specific Rules

- Use `adaptive` thinking with `low` effort for simple tasks; reserve `high` for architecture.
- Run `/compact` at ~50% context. Run `/clear` between unrelated tasks.
- Use subagents for codebase exploration — keeps main context clean.
- When loading external data: prefer Jina Reader or Firecrawl markdown output.
- Never load full docs when a link or `@` import suffices.
- Point to specific files and line numbers in prompts — vague = expensive.

## Deep Docs (load only when needed)

- @docs/agent-token-shield.md
- @docs/agent-troubleshooting.md
