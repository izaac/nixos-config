## Claude-Specific

- Use `adaptive` thinking, `low` effort for simple task.
- Run `/compact` at ~50% context. Run `/clear` between unrelated task.
- Use subagent for codebase explore — keep main context clean.
- Never load full doc when link or `@` import enough.
- Point to specific file + line number in prompt.
- **Always query Context7** before implement pattern not 100% sure — especially test design (cleanup, fixtures, assertions), Playwright API, any library/framework best practice. Training data stale; Context7 current. Apply to main context + subagent.
