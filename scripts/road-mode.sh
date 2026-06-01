#!/usr/bin/env bash
# road-mode.sh — quick posture toggle for travel / hostile networks.
#
# on:  firewall stealth + block-all-incoming, Bluetooth off, route all
#      traffic through the Tailscale exit-node on $ROAD_EXIT_NODE.
#      Snapshots the working default route first so off has a known-good
#      gateway to restore.
# off: revert to defaults. Tailscale's exit-node teardown is asynchronous,
#      so we poll until its /1+/1 split-tunnel routes are gone before
#      checking the routing table; recovery then tries snapshot → DHCP
#      renew → cached-router add until a real default is back.
#
# All flips are runtime — no darwin-rebuild required. Re-runnable.
#
# Firewall + Tailscale need root (sudo'd per-command). Bluetooth is a
# user-session API — blueutil must run UNESCALATED, so this script
# itself stays as the caller and only sudoes the bits that need it.

set -euo pipefail

FW=/usr/libexec/ApplicationFirewall/socketfilterfw
EXIT_NODE="${ROAD_EXIT_NODE:-ninja}"
STATE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/road-mode"
STATE_FILE="$STATE_DIR/route.state"

if [[ $EUID -eq 0 ]]; then
  echo "road-mode.sh: do not run as root (blueutil needs the user session)" >&2
  echo "             sudo is invoked per-command from inside the script." >&2
  exit 1
fi

bt_set() {
  local state=$1
  if command -v blueutil >/dev/null; then
    blueutil -p "$state"
  else
    printf '  blueutil not on PATH — skipping Bluetooth toggle\n' >&2
    printf '  (run `just darwin-build` to install it)\n' >&2
  fi
}

ts_exit_node() {
  local node=$1
  if [[ -z $node ]]; then
    sudo tailscale set --exit-node=
  else
    sudo tailscale set --exit-node="$node" --exit-node-allow-lan-access=true
  fi
}

# Find the primary physical interface (first UP iface with an IPv4, skipping
# virtual ones). Used by ensure_default_route to know who to renew DHCP on.
primary_iface() {
  local iface ip
  for iface in $(ifconfig -lu); do
    case $iface in
      lo* | utun* | bridge* | gif* | stf* | awdl* | llw* | anpi* | ap*) continue ;;
    esac
    ip=$(ipconfig getifaddr "$iface" 2>/dev/null || true)
    if [[ -n $ip ]]; then
      printf '%s\n' "$iface"
      return 0
    fi
  done
  return 1
}

# Look for a default route on a real (non-tunnel) interface. macOS
# `route -n get default` does longest-prefix match and will happily match
# Tailscale's `0.0.0.0/1` split-tunnel route while the daemon is still
# tearing it down — falsely signalling "default present". Only the literal
# `default` line in netstat (i.e., 0.0.0.0/0) proves a real default is
# installed; reject it if it points at a virtual iface.
has_physical_default() {
  local netif
  while IFS= read -r netif; do
    case $netif in
      utun* | gif* | stf* | ipsec* | ppp* | llw* | awdl* | anpi* | ap* | "") continue ;;
      *) return 0 ;;
    esac
  done < <(netstat -rn -f inet 2>/dev/null | awk '$1 == "default" {print $NF}')
  return 1
}

# Tailscale's exit-node split-tunnel installs `0/1` and `128.0/1` routes
# via utun. Watching for those specifically (rather than just "any utun
# route") is what tells us teardown is actually finished after a clear.
ts_split_routes_present() {
  netstat -rn -f inet 2>/dev/null \
    | awk '$1 == "0/1" || $1 == "128.0/1" {found = 1} END {exit !found}'
}

# Poll for Tailscale's /1+/1 split-tunnel routes to drain. Returns as soon
# as they're gone (typically <300 ms in practice) and caps at ~3 s so we
# never block forever — the recovery path that follows is fine handling
# either outcome.
wait_for_ts_routes_drain() {
  local i=0
  while ((i < 30)); do
    if ! ts_split_routes_present; then
      return 0
    fi
    sleep 0.1
    ((i++))
  done
}

# Snapshot the currently-active default route before road-on installs the
# Tailscale /1+/1 override. Captures the real gateway in use, so on road-off
# we can restore exactly what was working — covers DHCP option 121 (classless
# static routes), multi-gateway APs, and PPP-style tethering that a bare
# `ipconfig getoption router` read would miss. Skips writing when the
# current default already points through a tunnel (e.g., re-running road-on
# while it's already on), so a good earlier snapshot isn't poisoned.
snapshot_default_route() {
  mkdir -p "$STATE_DIR"
  local route_info gw iface
  route_info=$(route -n get default 2>/dev/null || true)
  gw=$(awk '/gateway:/ {print $2}' <<<"$route_info")
  iface=$(awk '/interface:/ {print $2}' <<<"$route_info")
  case $iface in
    utun* | gif* | stf* | ipsec* | ppp*)
      if [[ -f $STATE_FILE ]]; then
        printf 'Existing snapshot preserved (current default via %s)\n' "$iface"
      else
        printf 'Default via %s — no clean snapshot to take\n' "$iface" >&2
      fi
      return 0
      ;;
  esac
  if [[ -n $gw && -n $iface ]]; then
    printf 'iface=%s\ngateway=%s\n' "$iface" "$gw" >"$STATE_FILE"
    printf 'Saved default route: %s via %s\n' "$gw" "$iface"
  else
    printf 'No default route to snapshot — already offline?\n' >&2
  fi
}

# Restore the snapshot only when the current primary interface still matches
# what was active at snapshot time; if you switched networks while road-on,
# the saved gateway is stale and would just install an unreachable route.
restore_from_snapshot() {
  [[ -f $STATE_FILE ]] || return 1
  local iface="" gateway=""
  # shellcheck source=/dev/null
  source "$STATE_FILE"
  [[ -n $iface && -n $gateway ]] || return 1

  local current
  current=$(primary_iface 2>/dev/null || true)
  if [[ $current != "$iface" ]]; then
    printf '  Snapshot stale (saved %s, now %s) — skipping\n' "$iface" "$current"
    return 1
  fi

  printf '  Restoring saved default %s via %s\n' "$gateway" "$iface"
  sudo route -n add default "$gateway" >/dev/null
}

# Recover a missing default route after Tailscale's exit-node teardown.
# Order of attempts (cheapest, most reliable first):
#   1. Restore the snapshot captured before road-on — known-good gateway
#      from the actual working session, no DHCP gymnastics required.
#   2. Force a DHCP refresh — catches AP changes mid-session and exotic
#      DHCP setups (option 121 classless static routes, multi-gateway).
#   3. Add the route from the cached DHCP router option as a last resort,
#      since `ipconfig set DHCP` can be a no-op when configd thinks the
#      existing lease is still valid.
ensure_default_route() {
  if has_physical_default; then
    rm -f "$STATE_FILE"
    return 0
  fi
  printf 'Default route missing — recovering\n'

  if restore_from_snapshot && has_physical_default; then
    printf '  Restored from snapshot\n'
    rm -f "$STATE_FILE"
    return 0
  fi

  local iface
  if ! iface=$(primary_iface); then
    printf '  No primary interface found — manual fix required\n' >&2
    return 1
  fi

  printf '  Renewing DHCP on %s\n' "$iface"
  sudo ipconfig set "$iface" DHCP

  local i=0
  while ((i < 20)); do
    if has_physical_default; then
      printf '  Default route restored via DHCP\n'
      rm -f "$STATE_FILE"
      return 0
    fi
    sleep 0.3
    ((i++))
  done

  local gw
  gw=$(ipconfig getoption "$iface" router 2>/dev/null || true)
  if [[ -n $gw ]]; then
    printf '  DHCP no-op — adding default via cached router %s\n' "$gw"
    sudo route -n add default "$gw" >/dev/null 2>&1 || true
    if has_physical_default; then
      rm -f "$STATE_FILE"
      return 0
    fi
  fi

  printf '  Could not recover default route — run manually:\n' >&2
  printf '    sudo route -n add default <gw>   (try the AP gateway)\n' >&2
  printf '    sudo ipconfig set %s DHCP        (force DHCP refresh)\n' "$iface" >&2
  return 1
}

road_on() {
  # Capture working default route BEFORE Tailscale installs the /1+/1
  # override, so road-off has a known-good fallback if DHCP renew lags.
  snapshot_default_route

  printf 'Firewall: stealth + block-all-incoming\n'
  sudo "$FW" --setstealthmode on >/dev/null
  sudo "$FW" --setblockall on >/dev/null

  printf 'Bluetooth: off\n'
  bt_set 0

  printf 'Tailscale exit-node: %s\n' "$EXIT_NODE"
  ts_exit_node "$EXIT_NODE"

  printf '\nRoad mode ON\n'
}

road_off() {
  printf 'Firewall: defaults (allow signed, no stealth)\n'
  sudo "$FW" --setstealthmode off >/dev/null
  sudo "$FW" --setblockall off >/dev/null

  printf 'Bluetooth: on\n'
  bt_set 1

  printf 'Tailscale exit-node: cleared\n'
  ts_exit_node ""
  # Poll until the daemon finishes ripping out its /1+/1 split-tunnel
  # routes; without this, has_physical_default would race and the
  # recovery logic below would have nothing left to fix.
  wait_for_ts_routes_drain

  ensure_default_route || true

  printf '\nRoad mode OFF\n'
}

road_status() {
  printf '== Firewall ==\n'
  "$FW" --getstealthmode
  "$FW" --getblockall
  printf '\n== Bluetooth ==\n'
  if command -v blueutil >/dev/null; then
    printf 'power: %s\n' "$(blueutil -p)"
  else
    printf 'blueutil not installed\n'
  fi
  printf '\n== Tailscale ==\n'
  tailscale status | awk 'NR==1{print; exit}'
  # Active exit-node lines end in "; exit node"; advertised-but-unused end in
  # "; offers exit node" — anchor the trailing form to distinguish them.
  local exit_line
  exit_line=$(tailscale status 2>/dev/null \
    | grep -E '; exit node[[:space:]]*$' || true)
  if [[ -n $exit_line ]]; then
    printf 'exit-node: %s (%s)\n' \
      "$(awk '{print $2}' <<<"$exit_line")" \
      "$(awk '{print $1}' <<<"$exit_line")"
  else
    printf 'exit-node: (none)\n'
  fi
}

# Guard the dispatch so `source road-mode.sh` from the test harness pulls in
# function definitions without firing the case below. The path comparison is
# the idiomatic bash test for "executed directly vs. sourced".
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  case "${1:-status}" in
    on | road-on) road_on ;;
    off | road-off) road_off ;;
    status) road_status ;;
    *)
      printf 'Usage: %s {on|off|status}\n' "$0" >&2
      exit 1
      ;;
  esac
fi
