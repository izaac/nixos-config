#!/usr/bin/env bash
# road-mode.sh — quick posture toggle for travel / hostile networks.
#
# on:  firewall stealth + block-all-incoming, Bluetooth off, route all
#      traffic through the Tailscale exit-node on $ROAD_EXIT_NODE.
# off: revert to defaults. If clearing the Tailscale exit-node leaves the
#      system without a default route (a known macOS race), DHCP is
#      renewed on the primary interface to restore connectivity.
#
# All flips are runtime — no darwin-rebuild required. Re-runnable.
#
# Firewall + Tailscale need root (sudo'd per-command). Bluetooth is a
# user-session API — blueutil must run UNESCALATED, so this script
# itself stays as the caller and only sudoes the bits that need it.

set -euo pipefail

FW=/usr/libexec/ApplicationFirewall/socketfilterfw
EXIT_NODE="${ROAD_EXIT_NODE:-ninja}"

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

# Tailscale's exit-node teardown sometimes leaves the routing table without a
# default route (the /1+/1 override is pulled before DHCP re-asserts). Detect
# and recover by renewing DHCP, with an explicit `route add` fallback.
ensure_default_route() {
  if route -n get default >/dev/null 2>&1; then
    return 0
  fi
  printf 'Default route missing — recovering\n'

  local iface
  if ! iface=$(primary_iface); then
    printf '  No primary interface found — manual fix required\n' >&2
    return 1
  fi

  printf '  Renewing DHCP on %s\n' "$iface"
  sudo ipconfig set "$iface" DHCP

  local i=0
  while ((i < 10)); do
    if route -n get default >/dev/null 2>&1; then
      printf '  Default route restored via DHCP\n'
      return 0
    fi
    sleep 0.3
    ((i++))
  done

  local gw
  gw=$(ipconfig getoption "$iface" router 2>/dev/null || true)
  if [[ -n $gw ]]; then
    printf '  DHCP slow — adding default via %s manually\n' "$gw"
    sudo route -n add default "$gw" >/dev/null
    return 0
  fi

  printf '  Could not recover default route — run manually:\n' >&2
  printf '    sudo ipconfig set %s DHCP\n' "$iface" >&2
  return 1
}

road_on() {
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

case "${1:-status}" in
  on | road-on) road_on ;;
  off | road-off) road_off ;;
  status) road_status ;;
  *)
    printf 'Usage: %s {on|off|status}\n' "$0" >&2
    exit 1
    ;;
esac
