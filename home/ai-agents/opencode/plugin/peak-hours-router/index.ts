// Peak-hours router: routes worker agents to off-peak discount models (UTC 16:30 - 00:30),
// and to a configured peak partner model during peak hours. Fully configurable via opencode.jsonc.

function isDeepSeekOffPeak(): boolean {
  const now = new Date();
  const utcMinutes = now.getUTCHours() * 60 + now.getUTCMinutes();
  // DeepSeek off-peak: UTC 16:30 (990 min) to UTC 00:30 (30 min)
  return utcMinutes >= 990 || utcMinutes < 30;
}

function parseModelRef(ref: unknown, defaultRef: { providerID: string; id: string }) {
  if (typeof ref === 'object' && ref !== null && 'providerID' in ref && 'id' in ref) {
    return ref as { providerID: string; id: string };
  }
  if (typeof ref === 'string') {
    const slash = ref.indexOf('/');
    if (slash > 0 && slash < ref.length - 1) {
      return { providerID: ref.slice(0, slash), id: ref.slice(slash + 1) };
    }
  }
  return defaultRef;
}

const DEFAULT_OFF_PEAK = { providerID: 'opencode-go', id: 'deepseek-v4.1-flash' };
const DEFAULT_PEAK = { providerID: 'opencode-go', id: 'qwen3.8-flash' };
const DEFAULT_AGENTS = ['explore', 'general', 'reviewer'];

export default {
  id: 'peak-hours-router',
  async setup(ctx: any) {
    const options = ctx.options ?? {};
    const offPeakModel = parseModelRef(options.offPeakModel, DEFAULT_OFF_PEAK);
    const peakModel = parseModelRef(options.peakModel, DEFAULT_PEAK);
    const agents: string[] = Array.isArray(options.agents)
      ? options.agents.filter((a: unknown) => typeof a === 'string')
      : DEFAULT_AGENTS;

    let currentModelId = '';

    const applyRouting = async () => {
      try {
        const offPeak = isDeepSeekOffPeak();
        const targetModel = offPeak ? offPeakModel : peakModel;

        if (currentModelId === targetModel.id) return;
        currentModelId = targetModel.id;

        await ctx.agent.transform((editor: any) => {
          for (const agentID of agents) {
            editor.update(agentID, (agent: any) => {
              agent.model = targetModel;
            });
          }
        });
        await ctx.agent.reload();
        console.info(
          `[peak-hours-router] Agents (${agents.join(', ')}) routed to ${targetModel.providerID}/${targetModel.id} (offPeak=${offPeak})`,
        );
      } catch (err) {
        console.error('[peak-hours-router] Routing update failed:', err);
      }
    };

    await applyRouting();
    // Re-evaluate every 10 minutes
    const timer = setInterval(() => void applyRouting(), 10 * 60 * 1000);
    return () => clearInterval(timer);
  },
};
