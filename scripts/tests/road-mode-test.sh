#!/usr/bin/env bash
# Fixture-based unit tests for road-mode.sh pure helpers.
#
# Runs offline as the unprivileged user — no network, no sudo. The script
# under test is sourced (its dispatch is guarded), then `tailscale` is
# shadowed with a shell function that emits canned fixtures so helper logic
# can be exercised deterministically.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROAD=$SCRIPT_DIR/../road-mode.sh

if [[ ! -f $ROAD ]]; then
  printf 'road-mode.sh not found at %s\n' "$ROAD" >&2
  exit 1
fi

# Sourcing pulls in functions; `set -e` from the script is disabled below
# so failed assertions print a diagnostic instead of killing the runner.
# shellcheck source=/dev/null
source "$ROAD"
set +e

pass=0
fail=0
fail_list=()

section() { printf '\n== %s ==\n' "$1"; }

assert_eq() {
  local label=$1 expected=$2 actual=$3
  if [[ $expected == "$actual" ]]; then
    pass=$((pass + 1))
    printf '  ok   %s\n' "$label"
  else
    fail=$((fail + 1))
    fail_list+=("$label (expected '$expected', got '$actual')")
    printf '  FAIL %s\n' "$label"
    printf '       expected: %s\n' "$expected"
    printf '       actual:   %s\n' "$actual"
  fi
}

# Helpers return 0/1 via exit code; capture as "true"/"false" strings for
# readable assertion diagnostics. stdout/stderr are discarded so functions
# that emit diagnostic lines don't pollute the captured value.
bool() { if "$@" >/dev/null 2>&1; then printf true; else printf false; fi; }

# ---------------------------------------------------------------------------
# Fixtures — tailscale status output
# ---------------------------------------------------------------------------

# Active exit node ("; exit node" at end of line).
fixture_ts_exit_active='100.111.111.112  fancy        izaac@  macOS    -
100.111.111.111  ninja        izaac@  linux    active; exit node; direct 107.2.19.132:41641
'

# Exit node offered but not active.
fixture_ts_exit_offered='100.111.111.112  fancy        izaac@  macOS    -
100.111.111.111  ninja        izaac@  linux    active; offers exit node; direct 107.2.19.132:41641
'

# No exit node at all.
fixture_ts_no_exit='100.111.111.112  fancy        izaac@  macOS    -
100.111.111.111  ninja        izaac@  linux    active; direct 107.2.19.132:41641
'

# Status JSON fragment — Online: true.
fixture_ts_json_online='{"ExitNodeStatus":{"ID":"abc123","Online":true,"ExitNode":true}}'

# Status JSON fragment — Online: false.
fixture_ts_json_offline='{"ExitNodeStatus":{"ID":"abc123","Online":false,"ExitNode":false}}'

# ---------------------------------------------------------------------------
# Function shadows. The helpers call `tailscale` by name; shell function
# lookup wins over the binary, so callers transparently get the fixture
# currently bound to the FIXTURE variables.
# ---------------------------------------------------------------------------

FIXTURE_TS_STATUS=""
FIXTURE_TS_JSON=""

tailscale() {
  case "$1" in
    status)
      if [[ "${2:-}" == "--json" ]]; then
        printf '%s' "$FIXTURE_TS_JSON"
      else
        printf '%s' "$FIXTURE_TS_STATUS"
      fi
      ;;
    set) return 0 ;;  # no-op for tests
  esac
}

# ---------------------------------------------------------------------------
# verify_exit_node_up — must return success when tailscale reports an
# active exit node, and cap out with failure when it doesn't.
# ---------------------------------------------------------------------------
section "verify_exit_node_up"

sleep() { :; }

FIXTURE_TS_STATUS=$fixture_ts_exit_active
FIXTURE_TS_JSON=$fixture_ts_json_online
assert_eq "active exit node → success" "true" "$(bool verify_exit_node_up)"

FIXTURE_TS_STATUS=$fixture_ts_exit_offered
FIXTURE_TS_JSON=$fixture_ts_json_online
assert_eq "offered but not active → caps out, returns failure" "false" "$(bool verify_exit_node_up)"

FIXTURE_TS_STATUS=$fixture_ts_no_exit
FIXTURE_TS_JSON=$fixture_ts_json_offline
assert_eq "no exit node → caps out, returns failure" "false" "$(bool verify_exit_node_up)"

unset -f sleep

# ---------------------------------------------------------------------------
# wait_for_exit_node_clear — must terminate and return success when no
# active exit node is present, and cap out when one persists.
# ---------------------------------------------------------------------------
section "wait_for_exit_node_clear"

sleep() { :; }

FIXTURE_TS_STATUS=$fixture_ts_no_exit
assert_eq "no exit node → returns success" "true" "$(bool wait_for_exit_node_clear)"

FIXTURE_TS_STATUS=$fixture_ts_exit_active
assert_eq "exit node persists → caps out" "true" "$(bool wait_for_exit_node_clear)"

unset -f sleep

# ---------------------------------------------------------------------------
# road_status — smoke test that it runs without error
# ---------------------------------------------------------------------------
section "road_status (smoke)"

# Shadow the firewall binary so it doesn't need root.
/usr/libexec/ApplicationFirewall/socketfilterfw() { printf 'mocked\n'; }

# Shadow blueutil
blueutil() { printf '1\n'; }

FIXTURE_TS_STATUS=$fixture_ts_exit_active
road_status >/dev/null 2>&1
assert_eq "road_status runs without error" "true" "$(bool road_status)"

unset -f /usr/libexec/ApplicationFirewall/socketfilterfw
unset -f blueutil

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
printf '\n%d passed, %d failed\n' "$pass" "$fail"
if ((fail > 0)); then
  printf '\nFailures:\n'
  for f in "${fail_list[@]}"; do
    printf '  - %s\n' "$f"
  done
  exit 1
fi
