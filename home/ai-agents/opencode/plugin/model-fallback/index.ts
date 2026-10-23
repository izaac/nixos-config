// Model fallback: when a provider keeps failing, switch the session to a
// fallback model from a configured chain and let OpenCode retry on it.
// Inert for any model that has no chain entry.

type Fallback = { from: string; to: string };

// Give up after this many switches in one session, so two mutually-failing
// models cannot ping-pong forever.
const MAX_SWITCHES = 2;

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

function prune(switched: Map<string, number>) {
  if (switched.size <= MAX_TRACKED_SESSIONS) return;
  for (const key of switched.keys()) {
    if (switched.size <= TRACKED_SESSIONS_AFTER_PRUNE) break;
    switched.delete(key);
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
        const chain = fallbacks.find((f) => f.from === current);
        if (!chain) return; // unconfigured model: leave OpenCode's own policy alone
        if (!(event.attempt >= attemptsBeforeFallback)) return;

        const used = switched.get(event.sessionID) ?? 0;
        if (used >= MAX_SWITCHES) return;

        const target = parseModel(chain.to);
        if (!target) {
          console.error(
            `[model-fallback] bad chain target "${chain.to}", leaving retry policy untouched`,
          );
          return;
        }

        await ctx.session.switchModel({ sessionID: event.sessionID, model: target });
        switched.set(event.sessionID, used + 1);
        prune(switched);
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
