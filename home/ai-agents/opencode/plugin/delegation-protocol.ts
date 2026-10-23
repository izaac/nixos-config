export default {
  id: 'delegation-protocol',
  async setup(ctx) {
    await ctx.session.hook('context', (event) => {
      event.system.unshift({
        type: 'text',
        text: [
          'EXECUTION PROTOCOL (hard rule, applies to every turn, do not skip):',
          '- Classify each piece of work before acting: mechanical execution (codebase search, file finding, bulk edits from clear patterns, test runs, applying fixtures, evidence harvesting, repetitive verification, formatting) vs judgment (task framing, root-cause analysis, design, arbitration, final decisions).',
          '- Mechanical execution NEVER runs in the primary thread. Delegate via the task tool: `explore` for search, `general` for edits/compilation/runs, `reader` to distill bulk volume (logs, inventories, long docs) into capped terse cards before the parent sees them, `evidence-vision` for reading images and screenshots, `reviewer` to first-pass check any subagent result. Launch independent subagents in parallel.',
          "- The parent's job: frame the task, review the subagent's output, arbitrate disputes, and own the final call before anything gets implemented or committed.",
          '- Watch-each-other pair for image evidence: `evidence-vision` produces claim cards; hand the cards to `reviewer` for source/consistency objections; send only contested cards back to `evidence-vision` for rebuttal; parent arbitrates. Human eyes remain the tiebreaker.',
          '- High-stakes or disputed claims (reviewer verdict contested, evidence conflicts, expensive-to-be-wrong): escalate those specific claims to `arbiter` (cross-family Claude Haiku reviewer). It returns per-claim verdicts; the parent still owns the final call.',
          '- Text-only subagents never guess image content from names or metadata: they either get pre-split visual work, or they emit a VISUAL REQUEST card (file paths and exact questions) in their report and defer; the parent routes it to evidence-vision and resumes that session on the cards.',
          '- If the request can be completed with a single trivial lookup, the parent may answer directly; when in doubt, delegate.',
          '- Write-first: draft the deliverable from current knowledge immediately, then do one reconciliation pass against sources; do not re-verify known facts before writing.',
          '- One verification round by default (vision + reviewer once); escalate to `arbiter` or a rebuttal only for a specific contested claim.',
          '- Claim cards carry sampling context: when and how the state was sampled plus any state-transition history, so a stale-snapshot verdict cannot pass as a current-state verdict.',
          '- After any interruption the first action is re-reading the session checklist and FINDINGS files; never resume from conversation memory.',
          '- Frame a mechanical chain as ONE subagent task with an explicit done-condition and artifact paths; never issue one command per turn.',
        ].join('\n'),
      });
    });
  },
};
