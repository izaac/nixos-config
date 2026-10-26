// Peak-hours router: routes worker agents to off-peak discount models (UTC 16:30 - 00:30),
// and to a configured peak partner model during peak hours. Fully configurable via opencode.jsonc.
//
// Two configuration styles are supported, and may be mixed:
//   1. Per-agent routes (preferred):
//        "routes": {
//          "explore":  { "offPeak": "provider/model", "peak": "provider/model" },
//          "reviewer": { "offPeak": "provider/model", "peak": "provider/model" }
//        }
//   2. Legacy shared models, applied to every agent in "agents":
//        "offPeakModel": "provider/model", "peakModel": "provider/model",
//        "agents": ["explore", "general", "reviewer"]
// Agents listed in "routes" use their own pair; legacy "agents" entries that are not
// present in "routes" fall back to the shared offPeakModel/peakModel pair.

type ModelRef = { providerID: string; id: string };
type AgentRoute = { offPeak: ModelRef; peak: ModelRef };

function isDeepSeekOffPeak(): boolean {
  const now = new Date();
  const utcMinutes = now.getUTCHours() * 60 + now.getUTCMinutes();
  // DeepSeek off-peak: UTC 16:30 (990 min) to UTC 00:30 (30 min)
  return utcMinutes >= 990 || utcMinutes < 30;
}

function parseModelRef(ref: unknown, defaultRef: ModelRef): ModelRef {
  if (typeof ref === 'object' && ref !== null && 'providerID' in ref && 'id' in ref) {
    return ref as ModelRef;
  }
  if (typeof ref === 'string') {
    const slash = ref.indexOf('/');
    if (slash > 0 && slash < ref.length - 1) {
      return { providerID: ref.slice(0, slash), id: ref.slice(slash + 1) };
    }
  }
  return defaultRef;
}

const DEFAULT_OFF_PEAK: ModelRef = { providerID: 'opencode-go', id: 'deepseek-v4.1-flash' };
const DEFAULT_PEAK: ModelRef = { providerID: 'opencode-go', id: 'qwen3.8-flash' };
const DEFAULT_AGENTS = ['explore', 'general', 'reviewer'];

// Build the agent -> { offPeak, peak } map from options, honouring both styles.
function buildRoutes(options: any): Map<string, AgentRoute> {
  const routes = new Map<string, AgentRoute>();
  const legacyOffPeak = parseModelRef(options.offPeakModel, DEFAULT_OFF_PEAK);
  const legacyPeak = parseModelRef(options.peakModel, DEFAULT_PEAK);
  const legacyAgents: string[] = Array.isArray(options.agents)
    ? options.agents.filter((a: unknown) => typeof a === 'string')
    : DEFAULT_AGENTS;

  const rawRoutes = options.routes;
  if (rawRoutes && typeof rawRoutes === 'object' && !Array.isArray(rawRoutes)) {
    for (const [agentID, value] of Object.entries(rawRoutes)) {
      if (typeof agentID !== 'string' || !agentID) continue;
      if (!value || typeof value !== 'object') continue;
      const route = value as any;
      routes.set(agentID, {
        offPeak: parseModelRef(route.offPeak, legacyOffPeak),
        peak: parseModelRef(route.peak, legacyPeak),
      });
    }
  }

  // Legacy path: only fill agents that "routes" did not already cover. When no routes are
  // configured at all, this reproduces the original shared-model behaviour exactly.
  for (const agentID of legacyAgents) {
    if (routes.has(agentID)) continue;
    routes.set(agentID, { offPeak: legacyOffPeak, peak: legacyPeak });
  }

  return routes;
}

export default {
  id: 'peak-hours-router',
  async setup(ctx: any) {
    const options = ctx.options ?? {};
    const routes = buildRoutes(options);

    let currentSignature = '';

    const applyRouting = async () => {
      try {
        const offPeak = isDeepSeekOffPeak();
        const targets: Array<[string, ModelRef]> = [];
        for (const [agentID, route] of routes) {
          targets.push([agentID, offPeak ? route.offPeak : route.peak]);
        }

        const signature = targets
          .map(([agentID, model]) => `${agentID}=${model.providerID}/${model.id}`)
          .sort()
          .join('|');
        if (signature === currentSignature) return;
        currentSignature = signature;

        await ctx.agent.transform((editor: any) => {
          for (const [agentID, model] of targets) {
            editor.update(agentID, (agent: any) => {
              agent.model = model;
            });
          }
        });
        await ctx.agent.reload();
        const summary = targets
          .map(([agentID, model]) => `${agentID}->${model.providerID}/${model.id}`)
          .join(', ');
        console.info(`[peak-hours-router] ${summary} (offPeak=${offPeak})`);
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
