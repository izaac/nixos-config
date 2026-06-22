#!/usr/bin/env bash
# road-mode.sh — quick posture toggle for travel / hostile networks.
#
# on:  firewall stealth + block-all-incoming, Bluetooth off, route all
#      traffic through the Tailscale exit-node on $ROAD_EXIT_NODE.
# off: revert to defaults — clear the exit node, restore firewall and
#      Bluetooth.
#
# Requires the native macOS Tailscale GUI app (Network Extension). The CLI
# `tailscale set` commands talk to the GUI app's daemon; the NE handles
# routing and DNS properly — no BSD route or DNS hacks needed.
#
# All flips are runtime — no darwin-rebuild required. Re-runnable.
#
# Firewall needs root (sudo'd per-command). Bluetooth is a user-session
# API — blueutil must run UNESCALATED, so this script itself stays as the
# caller and only sudoes the bits that need it.

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
    tailscale set --exit-node= --accept-dns=false --accept-routes=true
  else
    # --accept-dns=true routes DNS through the exit node via MagicDNS.
    # --exit-node-allow-lan-access=false prevents DNS leaks to local router.
    # The GUI app's Network Extension handles the actual routing.
    tailscale set --exit-node="$node" --exit-node-allow-lan-access=false --accept-dns=true --accept-routes=true
  fi
}

# Verify exit-node is active by checking tailscale status JSON. The GUI
# app's Network Extension doesn't necessarily install BSD routing table
# entries — query the daemon directly instead.
verify_exit_node_up() {
  local i=0
  while ((i < 30)); do
    if tailscale status 2>/dev/null \
      | grep -E '; exit node' | grep -qvE '; offers exit node'; then
      printf '  Exit-node active ✓\n'
      return 0
    fi
    sleep 0.2
    i=$((i + 1))
  done
  printf '  WARNING: Exit-node did not become active after 6s.\n' >&2
  printf '           Check the Tailscale app and ensure %s is online.\n' "$EXIT_NODE" >&2
  return 1
}

# Wait for exit-node to clear after unsetting. Polls tailscale status
# until no active exit node line remains.
wait_for_exit_node_clear() {
  local i=0
  while ((i < 30)); do
    if ! tailscale status 2>/dev/null \
      | grep -E '; exit node' | grep -qvE '; offers exit node'; then
      return 0
    fi
    sleep 0.1
    i=$((i + 1))
  done
}

road_on() {
  printf 'Firewall: stealth + block-all-incoming\n'
  sudo "$FW" --setstealthmode on >/dev/null
  sudo "$FW" --setblockall on >/dev/null

  printf 'Bluetooth: off\n'
  bt_set 0

  printf 'Tailscale exit-node: %s\n' "$EXIT_NODE"
  ts_exit_node "$EXIT_NODE"
  verify_exit_node_up || true

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
  wait_for_exit_node_clear

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
    | grep -E '; exit node' | grep -vE '; offers exit node' || true)
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
