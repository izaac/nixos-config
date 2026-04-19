## Claude-Specific

- Use `adaptive` thinking with `low` effort for simple tasks.
- Run `/compact` at ~50% context. Run `/clear` between unrelated tasks.
- Use subagents for codebase exploration — keeps main context clean.
- Never load full docs when a link or `@` import suffices.
- Point to specific files and line numbers in prompts.
- **Always query Context7** before implementing patterns you are not 100% certain about — especially test design (cleanup, fixtures, assertions), Playwright API usage, and any library/framework best practices. Training data may be stale; Context7 has current docs. This applies to both main context and subagents.
