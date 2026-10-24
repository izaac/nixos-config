// Model fallback: when a provider keeps failing, switch the session to a
// fallback model from a configured chain and let OpenCode retry on it.
// Inert for any model that has no chain entry.

type Fallback = { from: string; to: string };

// Give up after this many switches in one session, so two mutually-failing
// models cannot ping-pong forever. Three permits an A -> B -> A -> C walk,
// where the return to A is a rung in, not a target, so no rung repeats.
const MAX_SWITCHES = 3;

function parseModel(ref: string) {
  const slash = ref.indexOf('/');
  if (slash <= 0 || slash === ref.length - 1) return;
  return { providerID: ref.slice(0, slash), id: ref.slice(slash + 1) };
}

// Note: on opencode 2.1.3 the detached service has no stdout sink, so these
// console lines do not reach the log file. The effective switch is recorded as
// a session model-switched entry instead; use that for post-hoc inspection.
function describe(err: any) {
  if (!err) return 'unknown';
  const status = err.status ?? err.type ?? 'unknown';
  const message = typeof err.message === 'string' ? err.message.slice(0, 120) : '';
  return message ? `${status} ${message}` : String(status);
}

// The per-session switch map lives for the whole process, so keep it bounded:
// Map iteration order is insertion order, so the oldest sessions go first.
const MAX_TRACKED_SESSIONS = 200;
const TRACKED_SESSIONS_AFTER_PRUNE = 100;

function prune(map: Map<string, unknown>) {
  if (map.size <= MAX_TRACKED_SESSIONS) return;
  for (const key of map.keys()) {
    if (map.size <= TRACKED_SESSIONS_AFTER_PRUNE) break;
    map.delete(key);
  }
}

// Append-only switch journal, since the detached service has no stdout sink.
// Loaded lazily so the plugin keeps its zero-import module shape.
async function journal(line: string) {
  const home = process.env.HOME;
  if (!home) return;
  try {
    const { appendFile, mkdir } = await import('node:fs/promises');
    const dir = `${home}/.local/share/opencode`;
    await mkdir(dir, { recursive: true });
    await appendFile(`${dir}/model-fallback.log`, `${line}\n`, 'utf8');
  } catch {
    // Journaling is best effort; it must never affect the switch itself.
  }
}

export default {
  id: 'model-fallback',
  async setup(ctx) {
    const options = ctx.options ?? {};
    const fallbacks: Fallback[] = Array.isArray(options.fallbacks)
      ? options.fallbacks.filter((f) => f && typeof f.from === 'string' && typeof f.to === 'string')
      : [];
    const attemptsBeforeFallback =
      Number.isFinite(options.attemptsBeforeFallback) && options.attemptsBeforeFallback > 0
        ? options.attemptsBeforeFallback
        : 2;
    const retryDelayMs =
      Number.isFinite(options.retryDelayMs) && options.retryDelayMs >= 0
        ? options.retryDelayMs
        : 1000;

    // Per-session count of fallback switches already performed.
    const switched = new Map();
    // Per-session set of targets already switched to, so a repeated `from`
    // advances to the next rung instead of bouncing back to a used target.
    const visited = new Map<string, Set<string>>();

    if (fallbacks.length === 0) {
      console.info('[model-fallback] loaded with no chains, inert');
      return;
    }
    console.info(
      `[model-fallback] loaded ${fallbacks.length} chain entries, switching from attempt ${attemptsBeforeFallback} on`,
    );

    await ctx.session.hook('retry', async (event) => {
      try {
        const current = `${event.model?.providerID}/${event.model?.id}`;
        const candidates = fallbacks.filter((f) => f.from === current);
        // unconfigured model: leave OpenCode's own policy alone
        if (candidates.length === 0) return;
        // Lifecycle noise, not provider dark: a disposed plugin (e.g. a second
        // opencode instance disposing the shared auth plugin) says nothing
        // about the provider's config, quota or auth state. Switching on it
        // fires false positives whenever a standalone run collides.
        if (/disposed/i.test(event.error?.message ?? '')) return;
        // 200-with-unprocessable-body is transport noise, not provider dark:
        // the HTTP round trip succeeded but the response stream was cut
        // mid-flight (opencode restart, proxy hiccup aborting the SSE).
        // Demand one more failed attempt than usual before hopping so a
        // restart blip cannot move the session.
        const bodyNoise =
          (event.error?.status ?? event.error?.statusCode) === 200 ||
          /failed to process successful response/i.test(event.error?.message ?? '');
        const floor = bodyNoise ? attemptsBeforeFallback + 1 : attemptsBeforeFallback;
        if (!(event.attempt >= floor)) return;

        const used = switched.get(event.sessionID) ?? 0;
        if (used >= MAX_SWITCHES) return;

        // Take the first rung whose target is still unvisited; if every target
        // for this `from` was already used, keep the plain first-match behavior.
        const seen = visited.get(event.sessionID) ?? new Set<string>();
        const chain = candidates.find((f) => !seen.has(f.to)) ?? candidates[0];

        const target = parseModel(chain.to);
        if (!target) {
          console.error(
            `[model-fallback] bad chain target "${chain.to}", leaving retry policy untouched`,
          );
          return;
        }

        await ctx.session.switchModel({ sessionID: event.sessionID, model: target });
        switched.set(event.sessionID, used + 1);
        seen.add(chain.to);
        visited.set(event.sessionID, seen);
        prune(switched);
        prune(visited);
        event.decision = { retry: true, delay: retryDelayMs };
        const summary = describe(event.error);
        await journal(
          `${new Date().toISOString()} | ${event.sessionID} | ${current} -> ${chain.to} | ${summary}`,
        );
        console.info(
          `[model-fallback] switched ${current} -> ${chain.to} after ${summary} ` +
            `(attempt ${event.attempt}, switch ${used + 1}/${MAX_SWITCHES}, session ${event.sessionID})`,
        );
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        console.error(
          `[model-fallback] retry hook failed, leaving retry policy untouched: ${message}`,
        );
      }
    });
  },
};
