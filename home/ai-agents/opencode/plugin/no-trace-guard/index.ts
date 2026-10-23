// No-trace guard: reject shell commands that combine shell tracing with a
// credential path or env hint. Tracing a command that touches credentials would
// print secrets into the transcript and the session log. Tracing on its own is
// ordinary debugging and stays allowed.

const DEFAULT_PATTERNS = ['.dashboard-e2e', 'APPCO_'];

// `set -x` / `set -eux` / `set -o xtrace`, or an interpreter started with -x / --xtrace.
const SET_TRACE = /\bset\s+(-[a-z]*x[a-z]*|-o\s+xtrace)\b/;
const INTERP_TRACE =
  /\b(bash|zsh|sh|dash|ksh|fish)\b[^\n]*?\s(-[a-zA-Z]*x[a-zA-Z]*|--xtrace)(?:\s|$)/;

const BLOCKED =
  'Blocked: tracing (set -x / -x) is not allowed in commands that reference credential files. Re-run without tracing.';

function isTracing(command: string) {
  return SET_TRACE.test(command) || INTERP_TRACE.test(command);
}

export default {
  id: 'no-trace-guard',
  async setup(ctx) {
    const options = ctx.options ?? {};
    const patterns = (Array.isArray(options.patterns) ? options.patterns : DEFAULT_PATTERNS).filter(
      (pattern: unknown) => typeof pattern === 'string' && pattern.length > 0,
    );

    function shouldBlock(command: unknown) {
      if (typeof command !== 'string') return false;
      if (!isTracing(command)) return false;
      return patterns.some((pattern: string) => command.includes(pattern));
    }

    await ctx.shell.hook('create.before', (event) => {
      let block = false;
      try {
        block = shouldBlock(event?.command);
      } catch (err) {
        // Fail open: a guard bug must never break the shell tool.
        const message = err instanceof Error ? err.message : String(err);
        console.error(`[no-trace-guard] check failed, allowing command: ${message}`);
        return;
      }
      if (block) throw new Error(BLOCKED);
    });

    console.info(`[no-trace-guard] loaded with ${patterns.length} credential pattern(s)`);
  },
};
