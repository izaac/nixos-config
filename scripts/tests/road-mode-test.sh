#!/usr/bin/env bash
# Fixture-based unit tests for road-mode.sh pure helpers.
#
# Runs offline as the unprivileged user — no network, no sudo. The script
# under test is sourced (its dispatch is guarded), then `netstat` and
# `route` are shadowed with shell functions that emit canned fixtures so
# helper logic can be exercised deterministically.

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
# that emit diagnostic lines (e.g., restore_from_snapshot) don't pollute
# the captured value.
bool() { if "$@" >/dev/null 2>&1; then printf true; else printf false; fi; }

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

# Real default on en0, no Tailscale routes.
fixture_default_en0='Routing tables

Internet:
Destination        Gateway            Flags               Netif Expire
default            192.168.0.1        UGScg                 en0
127                127.0.0.1          UCS                   lo0
'

# Only a tunneled default (e.g., always-on VPN with no physical default).
fixture_default_utun='Routing tables

Internet:
Destination        Gateway            Flags               Netif Expire
default            100.64.0.1         UGScg                 utun5
127                127.0.0.1          UCS                   lo0
'

# Real default plus Tailscale split-tunnel /1+/1 — the exact post-exit-node
# state that fooled the old `route -n get default` check.
fixture_ts_split='Routing tables

Internet:
Destination        Gateway            Flags               Netif Expire
0/1                100.64.0.1         UGSc                  utun5
128.0/1            100.64.0.1         UGSc                  utun5
default            192.168.0.1        UGScg                 en0
127                127.0.0.1          UCS                   lo0
'

# /1 routes present but the real default is gone — what the system looks
# like during the brief window before TS finishes its async teardown.
fixture_ts_split_no_default='Routing tables

Internet:
Destination        Gateway            Flags               Netif Expire
0/1                100.64.0.1         UGSc                  utun5
128.0/1            100.64.0.1         UGSc                  utun5
127                127.0.0.1          UCS                   lo0
'

# Empty routing table (offline).
fixture_no_default='Routing tables

Internet:
Destination        Gateway            Flags               Netif Expire
127                127.0.0.1          UCS                   lo0
'

# `route -n get default` outputs for snapshot_default_route fixtures.
route_get_en0='   route to: default
destination: default
       mask: default
    gateway: 192.168.0.1
  interface: en0
      flags: <UP,GATEWAY,DONE,STATIC,PRCLONING,GLOBAL>
'

route_get_utun='   route to: default
destination: default
       mask: default
    gateway: 100.64.0.1
  interface: utun5
      flags: <UP,GATEWAY,DONE,STATIC>
'

# ---------------------------------------------------------------------------
# Function shadows. The helpers call `netstat` / `route` by name; shell
# function lookup wins over the binary, so callers transparently get the
# fixture currently bound to $FIXTURE_NETSTAT / $FIXTURE_ROUTE_GET.
# ---------------------------------------------------------------------------

FIXTURE_NETSTAT=""
FIXTURE_ROUTE_GET=""

netstat() { printf '%s' "$FIXTURE_NETSTAT"; }
route() { printf '%s' "$FIXTURE_ROUTE_GET"; }

# ---------------------------------------------------------------------------
# has_physical_default
# ---------------------------------------------------------------------------
section "has_physical_default"

FIXTURE_NETSTAT=$fixture_default_en0
assert_eq "real default on en0 → true" "true" "$(bool has_physical_default)"

FIXTURE_NETSTAT=$fixture_default_utun
assert_eq "default via utun only → false" "false" "$(bool has_physical_default)"

FIXTURE_NETSTAT=$fixture_ts_split
assert_eq "real default + TS split-tunnel → true (ignores /1 lines)" "true" "$(bool has_physical_default)"

FIXTURE_NETSTAT=$fixture_ts_split_no_default
assert_eq "TS split-tunnel without real default → false (the bug regression case)" "false" "$(bool has_physical_default)"

FIXTURE_NETSTAT=$fixture_no_default
assert_eq "empty table → false" "false" "$(bool has_physical_default)"

# ---------------------------------------------------------------------------
# ts_split_routes_present
# ---------------------------------------------------------------------------
section "ts_split_routes_present"

FIXTURE_NETSTAT=$fixture_ts_split
assert_eq "0/1 and 128.0/1 present → true" "true" "$(bool ts_split_routes_present)"

FIXTURE_NETSTAT=$fixture_ts_split_no_default
assert_eq "/1 routes without default → true (drain not done yet)" "true" "$(bool ts_split_routes_present)"

FIXTURE_NETSTAT=$fixture_default_en0
assert_eq "real default, no /1 routes → false (drain complete)" "false" "$(bool ts_split_routes_present)"

FIXTURE_NETSTAT=$fixture_no_default
assert_eq "empty table → false" "false" "$(bool ts_split_routes_present)"

# ---------------------------------------------------------------------------
# snapshot_default_route — verify state-file behavior
# ---------------------------------------------------------------------------
section "snapshot_default_route"

tmpdir=$(mktemp -d)
STATE_DIR="$tmpdir"
STATE_FILE="$tmpdir/route.state"

FIXTURE_ROUTE_GET=$route_get_en0
snapshot_default_route >/dev/null 2>&1
assert_eq "physical default → state file written" "true" "$(bool test -f "$STATE_FILE")"
assert_eq "state file content" "iface=en0
gateway=192.168.0.1" "$(cat "$STATE_FILE")"

# Re-run with a tunneled default — must NOT overwrite the good snapshot.
FIXTURE_ROUTE_GET=$route_get_utun
snapshot_default_route >/dev/null 2>&1
assert_eq "tunneled default + existing snapshot → preserved" "iface=en0
gateway=192.168.0.1" "$(cat "$STATE_FILE")"

# Fresh state dir, tunneled default — no file should be written.
rm -f "$STATE_FILE"
FIXTURE_ROUTE_GET=$route_get_utun
snapshot_default_route >/dev/null 2>&1
assert_eq "tunneled default, no prior snapshot → no file" "false" "$(bool test -f "$STATE_FILE")"

# No default at all.
FIXTURE_ROUTE_GET=''
snapshot_default_route >/dev/null 2>&1
assert_eq "no default → no file" "false" "$(bool test -f "$STATE_FILE")"

rm -rf "$tmpdir"

# ---------------------------------------------------------------------------
# restore_from_snapshot — stale detection, state-file handling
# ---------------------------------------------------------------------------
section "restore_from_snapshot"

# Replace primary_iface and sudo so we exercise only the decision logic.
# Original primary_iface walks `ifconfig`; we want a controllable value.
# sudo would prompt for password and mutate the routing table; we just
# need it to look like the route add succeeded.
MOCK_PRIMARY_IFACE=""
primary_iface() {
  [[ -n $MOCK_PRIMARY_IFACE ]] && printf '%s\n' "$MOCK_PRIMARY_IFACE" && return 0
  return 1
}
sudo() {
  if [[ $# -ge 1 && $1 == "route" ]]; then return 0; fi
  command sudo "$@"
}

tmpdir=$(mktemp -d)
STATE_FILE="$tmpdir/route.state"

# Matching iface — restore should proceed.
printf 'iface=en0\ngateway=192.168.0.1\n' >"$STATE_FILE"
MOCK_PRIMARY_IFACE=en0
assert_eq "matching iface → restore proceeds" "true" "$(bool restore_from_snapshot)"

# Stale iface — restore must be skipped.
MOCK_PRIMARY_IFACE=en1
assert_eq "stale iface (saved en0, now en1) → skipped" "false" "$(bool restore_from_snapshot)"

# Missing state file.
rm -f "$STATE_FILE"
MOCK_PRIMARY_IFACE=en0
assert_eq "no state file → skipped" "false" "$(bool restore_from_snapshot)"

# Empty fields in state file.
printf 'iface=\ngateway=\n' >"$STATE_FILE"
assert_eq "empty fields → skipped" "false" "$(bool restore_from_snapshot)"

rm -rf "$tmpdir"

# ---------------------------------------------------------------------------
# wait_for_ts_routes_drain — must terminate under set -e (the ((i++))
# regression aborted road_off whenever routes were still present on the
# first poll). sleep is shadowed so the stuck case doesn't take 3 s.
# ---------------------------------------------------------------------------
section "wait_for_ts_routes_drain"

sleep() { :; }

FIXTURE_NETSTAT=$fixture_default_en0
assert_eq "routes already gone → returns success" "true" "$(bool wait_for_ts_routes_drain)"

# By design the cap-out path still returns success — the recovery code
# after it handles either outcome. The regression this guards: ((i++))
# under set -e aborted the whole script instead of ever reaching the cap.
FIXTURE_NETSTAT=$fixture_ts_split
assert_eq "routes never drain → caps out and returns" "true" "$(bool wait_for_ts_routes_drain)"

unset -f sleep

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
