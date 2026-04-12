# Token Optimization Playbook

> Tier 2 doc — loaded on demand. Consolidated from Anthropic docs, community research, and best practices.

---

## 1. Data Cleanup

| Technique | Tool | When |
| --------- | ---- | ---- |
| Markdown conversion | Firecrawl, Jina Reader | Scraping websites — strip ads, nav, footers |
| PDF extraction | Unstructured.io | Ingesting scanned/messy PDFs |
| Strip boilerplate | Manual or Firecrawl page selector | Remove headers/footers before prompting |

**Rule:** Never feed raw HTML or unprocessed PDFs to the model. Clean first, prompt second.

---

## 2. Context Sizing

- **Stay under 200k tokens** — input price nearly doubles above this on Sonnet/Opus.
- **Truncate to top content** — first 5k words of long docs usually contain key info.
- **Tiered architecture:**
  - **Tier 1 (<800 tokens):** Always loaded — identity, rules, quick-start.
  - **Tier 2 (500–1500 tokens):** On-demand — component docs, API refs, deploy guides.
  - **Tier 3 (0 tokens):** Linked, never loaded — full specs, changelogs, generated docs.

---

## 3. Preprocessing

- **Haiku for dirty work:** Pre-summarize raw data with Haiku before sending to Sonnet/Opus.
- **Semantic chunking:** Use Llama-Index or similar to split docs, retrieve only matching paragraphs.
- **Semantic search before truncate:** Index first, search keywords, pull top matches — don't chop blindly.

---

## 4. Session Management

| Action | Command | When |
| ------ | ------- | ---- |
| Clear context | `/clear` | Between unrelated tasks |
| Compact context | `/compact` | At ~50% context usage |
| Check context | `/context` | Periodically during long sessions |
| Check usage | `/usage` | Monitor token spend |

- **One chat per task.** Don't mix feature work, debugging, and questions in one window.
- **Subagents for exploration.** They run in separate context, report back summaries.
- **Specific prompts.** Include file paths, line numbers, error messages. Vague = expensive.

---

## 5. Model Selection

| Task Type | Model | Why |
| --------- | ----- | --- |
| File reads, syntax questions, simple refactors | Haiku | Fast, cheap |
| Complex architecture, multi-file refactors, debugging | Sonnet/Opus | Reasoning power |

**Always set model deliberately.** Never rely on defaults.

---

## 6. Prompt Caching

- **Consistent formatting** across requests — same structure triggers cache hits.
- **Cache reads cost 10% of base input** — massive savings on repeated context.
- **5-minute default TTL** — refreshed each time cached content is reused.
- **Place static content first** — tools, system, then messages (in that order).
- **Don't change tool definitions, thinking params, or citations toggle mid-conversation** — invalidates cache.

---

## 7. CLAUDE.md / AGENTS.md Best Practices

- **Keep it short.** For each line ask: "Would removing this cause mistakes?" If not, cut it.
- **Only include what the agent can't infer** from reading code.
- **Use `@path/to/file` imports** (Claude Code) to load docs on demand.
- **Use skills** for domain knowledge that's only sometimes relevant.
- **Prune regularly.** Treat instruction files like code — review when things go wrong.
- **Emphasis works.** "IMPORTANT" or "YOU MUST" improves adherence for critical rules.

---

## 8. File Exclusions

Create `.claudeignore` (Claude Code) or equivalent:
```
node_modules/
build/
dist/
result/
.git/
*.log
```
Less scanning = fewer tokens.

---

## 9. Monitoring

| Tool | Purpose |
| ---- | ------- |
| `/usage` | Session + weekly token totals |
| [claude.ai/settings/usage](https://claude.ai/settings/usage) | Dashboard (auto-refreshes) |
| [claude-hud](https://github.com/jarrodwatts/claude-hud) | Real-time context bar in terminal |
| `claude -p "..."` | Headless mode — fewer tokens than interactive |

---

## 10. Safety

- **Set hard spending limits** in Anthropic console — tiered rate limits + alerts.
- **Budget per session** — don't let runaway loops drain the account.
- **Review token usage weekly** — catch inefficiencies early.

---

## Sources

- [Anthropic Prompt Caching Docs](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
- [Anthropic Claude Code Best Practices](https://docs.anthropic.com/en/docs/claude-code/best-practices)
- [12 Proven Techniques (aslamdoctor.com)](https://aslamdoctor.com/12-proven-techniques-to-save-tokens-in-claude-code/)
- [Optimize Context by 60% (Medium/Jpranav)](https://medium.com/@jpranav97/stop-wasting-tokens-how-to-optimize-claude-code-context-by-60-bfad6fd477e5)
- Reddit: u/Grouchy_Subject_2777, u/Capable-Pool759, u/ComfortableHot6840, u/TaskSpecialist5881
