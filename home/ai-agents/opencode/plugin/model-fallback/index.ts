// Model fallback: when a provider keeps failing, switch the session to a
// fallback model from a configured chain and let OpenCode retry on it.
// Includes automatic circuit-breaker self-healing to restore the primary model
// after an outage/quota cooldown.

type Fallback = { from: string; to: string };

const MAX_SWITCHES = 3;

function parseModel(ref: string) {
  const slash = ref.indexOf('/');
  if (slash <= 0 || slash === ref.length - 1) return;
  return { providerID: ref.slice(0, slash), id: ref.slice(slash + 1) };
}

function getFullErrorMessage(err: any): string {
  if (!err) return '';
  if (typeof err === 'string') return err;
  const parts = [
    typeof err.message === 'string' ? err.message : '',
    typeof err.status === 'string' || typeof err.status === 'number' ? String(err.status) : '',
    typeof err.statusCode === 'string' || typeof err.statusCode === 'number'
      ? String(err.statusCode)
      : '',
    typeof err.type === 'string' ? err.type : '',
    typeof err.code === 'string' ? err.code : '',
    typeof err.cause?.message === 'string' ? err.cause.message : '',
    typeof err.error?.message === 'string' ? err.error.message : '',
    typeof err.response?.statusText === 'string' ? err.response.statusText : '',
  ].filter(Boolean);
  return parts.join(' ');
}

type ErrorCategory = 'lifecycle' | 'stream' | 'quota' | 'outage' | 'other';

function classifyError(err: any): ErrorCategory {
  const text = getFullErrorMessage(err);
  const status = Number(err?.status ?? err?.statusCode);

  // 1. Lifecycle / Generation transients:
  if (/disposed|accounts? (have )?changed|token refresh temporarily unavailable/i.test(text)) {
    return 'lifecycle';
  }

  // 2. Quota / Rate limits:
  if (status === 429 || /provider\.quota|free-limit|quota protection|quota resets in/i.test(text)) {
    return 'quota';
  }

  // 3. Stream transport cuts (200 with unprocessable body / SSE abort):
  if (status === 200 || /failed to process successful response/i.test(text)) {
    return 'stream';
  }

  // 4. Upstream outages (5xx, timeouts, connection drops):
  if (
    (status >= 500 && status < 600) ||
    /provider\.internal|ECONNRESET|ETIMEDOUT|fetch failed|network timeout/i.test(text)
  ) {
    return 'outage';
  }

  return 'other';
}

function describe(err: any) {
  if (!err) return 'unknown';
  const status = err.status ?? err.type ?? 'unknown';
  const message = typeof err.message === 'string' ? err.message.slice(0, 120) : '';
  return message ? `${status} ${message}` : String(status);
}

const MAX_TRACKED_SESSIONS = 200;
const TRACKED_SESSIONS_AFTER_PRUNE = 100;

function prune(map: Map<string, unknown>) {
  if (map.size <= MAX_TRACKED_SESSIONS) return;
  for (const key of map.keys()) {
    if (map.size <= TRACKED_SESSIONS_AFTER_PRUNE) break;
    map.delete(key);
  }
}

async function journal(line: string) {
  const home = process.env.HOME;
  if (!home) return;
  try {
    const { appendFile, mkdir } = await import('node:fs/promises');
    const dir = `${home}/.local/share/opencode`;
    await mkdir(dir, { recursive: true });
    await appendFile(`${dir}/model-fallback.log`, `${line}\n`, 'utf8');
  } catch {}
}

type SessionLease = {
  preferred: string;
  fallback: string;
  switchedAt: number;
  cooldownMs: number;
};

export default {
  id: 'model-fallback',
  async setup(ctx: any) {
    const options = ctx.options ?? {};
    const fallbacks: Fallback[] = Array.isArray(options.fallbacks)
      ? options.fallbacks.filter(
          (f: any) => f && typeof f.from === 'string' && typeof f.to === 'string',
        )
      : [];
    const attemptsBeforeFallback =
      Number.isFinite(options.attemptsBeforeFallback) && options.attemptsBeforeFallback > 0
        ? options.attemptsBeforeFallback
        : 3;
    const retryDelayMs =
      Number.isFinite(options.retryDelayMs) && options.retryDelayMs >= 0
        ? options.retryDelayMs
        : 1000;

    const switched = new Map<string, number>();
    const visited = new Map<string, Set<string>>();
    const leases = new Map<string, SessionLease>();

    if (fallbacks.length === 0) {
      console.info('[model-fallback] loaded with no chains, inert');
      return;
    }
    console.info(
      `[model-fallback] loaded ${fallbacks.length} chain entries, switching from attempt ${attemptsBeforeFallback} on`,
    );

    // Automatic recovery: on each new turn context preparation, check if a session
    // that previously fell back has cooled down. If so, probe and restore the primary model.
    await ctx.session.hook('context', async (event: any) => {
      try {
        const lease = leases.get(event.sessionID);
        if (!lease) return;

        const now = Date.now();
        if (now - lease.switchedAt < lease.cooldownMs) return;

        const current = `${event.model?.providerID}/${event.model?.id}`;
        if (current !== lease.fallback) {
          // User or another system changed the model manually: release lease
          leases.delete(event.sessionID);
          return;
        }

        const target = parseModel(lease.preferred);
        if (!target) {
          leases.delete(event.sessionID);
          return;
        }

        leases.delete(event.sessionID);
        switched.delete(event.sessionID);
        visited.delete(event.sessionID);

        await ctx.session.switchModel({ sessionID: event.sessionID, model: target });
        await journal(
          `${new Date().toISOString()} | ${event.sessionID} | probed/restored ${lease.fallback} -> ${lease.preferred} after cooldown`,
        );
        console.info(
          `[model-fallback] restored primary ${lease.preferred} for session ${event.sessionID} after cooldown`,
        );
      } catch (err) {
        console.error('[model-fallback] context restoration hook failed:', err);
      }
    });

    await ctx.session.hook('retry', async (event: any) => {
      try {
        const current = `${event.model?.providerID}/${event.model?.id}`;
        const candidates = fallbacks.filter((f) => f.from === current);
        if (candidates.length === 0) return;

        const category = classifyError(event.error);

        // 1. Lifecycle noise: never failover. Let same-model retry run on the reloaded instance.
        if (category === 'lifecycle') return;

        // 2. Other unhandled/syntax/bad-request errors: do not failover.
        if (category === 'other') return;

        // 3. Compute attempt threshold by category:
        // - Quota: immediate failover (floor = 2: first retry arrives with attempt=2)
        // - Stream cuts: require 2 same-model retries (floor = attemptsBeforeFallback + 2)
        // - Outages (5xx, timeout, network): standard threshold (floor = attemptsBeforeFallback)
        let floor = attemptsBeforeFallback;
        if (category === 'quota') {
          floor = 2;
        } else if (category === 'stream') {
          floor = attemptsBeforeFallback + 2;
        }

        if (event.attempt < floor) return;

        const used = switched.get(event.sessionID) ?? 0;
        if (used >= MAX_SWITCHES) return;

        const seen = visited.get(event.sessionID) ?? new Set<string>();
        const chain = candidates.find((f) => !seen.has(f.to)) ?? candidates[0];

        const target = parseModel(chain.to);
        if (!target) {
          console.error(
            `[model-fallback] bad chain target "${chain.to}", leaving retry policy untouched`,
          );
          return;
        }

        // Track execution lease for automatic self-healing recovery
        const cooldownMs = category === 'quota' ? 15 * 60 * 1000 : 5 * 60 * 1000;
        leases.set(event.sessionID, {
          preferred: current,
          fallback: chain.to,
          switchedAt: Date.now(),
          cooldownMs,
        });

        await ctx.session.switchModel({ sessionID: event.sessionID, model: target });
        switched.set(event.sessionID, used + 1);
        seen.add(chain.to);
        visited.set(event.sessionID, seen);
        prune(switched);
        prune(visited);
        prune(leases);

        event.decision = { retry: true, delay: retryDelayMs };
        const summary = describe(event.error);
        await journal(
          `${new Date().toISOString()} | ${event.sessionID} | ${current} -> ${chain.to} | [${category}] ${summary}`,
        );
        console.info(
          `[model-fallback] switched ${current} -> ${chain.to} after [${category}] ${summary} ` +
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
