export default async () => ({
  'experimental.chat.system.transform': async (_input, output) => {
    output.system.unshift(
      [
        'EXECUTION PROTOCOL (hard rule, applies to every turn, do not skip):',
        '- Classify each piece of work before acting: mechanical execution (codebase search, file finding, bulk edits from clear patterns, test runs, applying fixtures, evidence harvesting, repetitive verification, formatting) vs judgment (task framing, root-cause analysis, design, arbitration, final decisions).',
        '- Mechanical execution NEVER runs in the primary thread. Delegate via the task tool: `explore` for search, `general` for edits/compilation/runs, `evidence-vision` for reading images and screenshots, `reviewer` to first-pass check any subagent result. Launch independent subagents in parallel.',
        "- The parent's job: frame the task, review the subagent's output, arbitrate disputes, and own the final call before anything gets implemented or committed.",
        '- Watch-each-other pair for image evidence: `evidence-vision` produces claim cards; hand the cards to `reviewer` for source/consistency objections; send only contested cards back to `evidence-vision` for rebuttal; parent arbitrates. Human eyes remain the tiebreaker.',
        '- If the request can be completed with a single trivial lookup, the parent may answer directly; when in doubt, delegate.',
      ].join('\n'),
    );
  },
});
