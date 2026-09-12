#!/usr/bin/env bash
# nvidia-check.sh — query and summarize NVIDIA driver versions across
# Nixpkgs channels (stable/unstable) and Upstream NVIDIA.
#
# Designed for high resilience:
# - Pure parser functions for testability
# - Bounded timeouts on all network & nix operations
# - Graceful fallbacks on network partitions or upstream layout shifts
# - Dual output modes: human-readable ANSI table or structured JSON

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
DIM='\033[2m'
NC='\033[0m'

# -----------------------------------------------------------------------------
# Pure Parser Functions (Deterministic & Testable)
# -----------------------------------------------------------------------------

# Extract version from NVIDIA unix.md markdown content
# Arguments: $1 = markdown content, $2 = "production" | "new_feature"
parse_unix_md() {
  local content="$1" branch="$2"
  local pattern="Latest Production Branch Version"
  if [[ $branch == "new_feature" ]]; then
    pattern="Latest New Feature Branch Version"
  fi

  local line
  line="$(echo "$content" | grep -m1 "$pattern" 2>/dev/null || true)"
  if [[ -z $line ]]; then
    echo "n/a"
    return
  fi

  local ver
  ver="$(echo "$line" | grep -oE '\[?[0-9]+\.[0-9]+(\.[0-9]+)?\]?' | head -n 1 | tr -d '[]' || true)"
  if [[ -n $ver ]]; then
    echo "$ver"
  else
    echo "n/a"
  fi
}

# Extract version from NVIDIA latest.txt
# Arguments: $1 = latest.txt content
parse_latest_txt() {
  local content="$1"
  local ver
  ver="$(echo "$content" | awk 'NR==1 {print $1}' 2>/dev/null || true)"
  if [[ $ver =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
    echo "$ver"
  else
    echo "n/a"
  fi
}

# Extract highest available version from download.nvidia.com HTML directory listing
# Arguments: $1 = directory listing HTML
parse_cdn_listing() {
  local content="$1"
  local ver
  ver="$(echo "$content" | grep -oE "href=['\"][0-9]+\.[0-9]+(\.[0-9]+)?/?['\"]" 2>/dev/null \
    | tr -d "href='\"/" \
    | sort -V 2>/dev/null \
    | tail -n 1 || true)"

  if [[ $ver =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
    echo "$ver"
  else
    echo "n/a"
  fi
}

# Extract latest release discussion thread title from forum RSS
# Arguments: $1 = RSS XML content
parse_forum_rss() {
  local content="$1"
  local topic
  topic="$(echo "$content" | grep -oE "<title>[0-9]+(\.[0-9]+)* release feedback[^<]*" 2>/dev/null \
    | head -n 1 \
    | sed -e 's/<title>//' -e 's/&amp;/\&/g' || true)"

  if [[ -n $topic ]]; then
    echo "$topic"
  else
    echo "n/a"
  fi
}

# Safe curl helper with bounded connection and transfer limits
# Arguments: $1 = url, $2 = max timeout in seconds (default 4)
safe_curl() {
  local url="$1" timeout="${2:-4}"
  if ! command -v curl >/dev/null 2>&1; then
    echo ""
    return 1
  fi
  curl --silent --show-error --connect-timeout 2 --max-time "$timeout" --location --fail "$url" 2>/dev/null || true
}

# -----------------------------------------------------------------------------
# Main Inspection Logic
# -----------------------------------------------------------------------------

run_nvidia_check() {
  local output_json=0
  if [[ ${1:-} == "--json" ]]; then
    output_json=1
  fi

  if [[ $output_json -eq 0 ]]; then
    printf '%b%bQuerying NVIDIA driver versions across channels...%b\n\n' "$BOLD" "$CYAN" "$NC"
  fi

  # 1. Local Host Pins
  local ninja_pin="n/a"
  if [[ -f "$REPO_ROOT/hosts/ninja/nvidia.nix" ]]; then
    ninja_pin="$(grep -oE 'version = "[^"]+"' "$REPO_ROOT/hosts/ninja/nvidia.nix" 2>/dev/null | head -n 1 | cut -d'"' -f2 || echo "n/a")"
  fi

  # 2. Flake Nixpkgs Channels (Safe bounded eval)
  local nix_stable_prod="n/a" nix_stable_latest="n/a"
  local nix_unstable_prod="n/a" nix_unstable_latest="n/a"

  if command -v nix >/dev/null 2>&1; then
    local nix_eval_cmd="nix eval --impure --json --expr '
      let
        flake = builtins.getFlake \"$REPO_ROOT\";
        sys = builtins.currentSystem or \"x86_64-linux\";
        targetSys = if builtins.isAttrs (flake.inputs.nixpkgs.legacyPackages or null) && builtins.hasAttr \"x86_64-linux\" flake.inputs.nixpkgs.legacyPackages
                    then \"x86_64-linux\" else sys;
        s = flake.inputs.nixpkgs.legacyPackages.\${targetSys}.linuxPackages.nvidiaPackages or {};
        u = flake.inputs.nixpkgs-unstable.legacyPackages.\${targetSys}.linuxPackages.nvidiaPackages or {};
      in {
        stable_prod = s.production.version or s.stable.version or \"n/a\";
        stable_latest = s.latest.version or \"n/a\";
        unstable_prod = u.production.version or u.stable.version or \"n/a\";
        unstable_latest = u.latest.version or \"n/a\";
      }
    '"

    local nix_raw="{}"
    if command -v timeout >/dev/null 2>&1; then
      nix_raw="$(timeout 8s bash -c "$nix_eval_cmd" 2>/dev/null || echo "{}")"
    else
      nix_raw="$(bash -c "$nix_eval_cmd" 2>/dev/null || echo "{}")"
    fi

    if command -v jq >/dev/null 2>&1 && [[ -n $nix_raw ]]; then
      nix_stable_prod="$(echo "$nix_raw" | jq -r '.stable_prod // "n/a"' 2>/dev/null || echo "n/a")"
      nix_stable_latest="$(echo "$nix_raw" | jq -r '.stable_latest // "n/a"' 2>/dev/null || echo "n/a")"
      nix_unstable_prod="$(echo "$nix_raw" | jq -r '.unstable_prod // "n/a"' 2>/dev/null || echo "n/a")"
      nix_unstable_latest="$(echo "$nix_raw" | jq -r '.unstable_latest // "n/a"' 2>/dev/null || echo "n/a")"
    fi
  fi

  # 3. Upstream Queries (with timeouts and resilient fallbacks)
  local unix_md_raw cdn_latest_raw cdn_index_raw forum_rss_raw
  unix_md_raw="$(safe_curl "https://www.nvidia.com/en-us/drivers/unix.md" 4)"
  cdn_latest_raw="$(safe_curl "https://download.nvidia.com/XFree86/Linux-x86_64/latest.txt" 3)"
  cdn_index_raw="$(safe_curl "https://download.nvidia.com/XFree86/Linux-x86_64/" 4)"
  forum_rss_raw="$(safe_curl "https://forums.developer.nvidia.com/c/gpu-graphics/linux/148.rss" 4)"

  local upstream_prod upstream_nfb cdn_latest cdn_edge forum_topic
  upstream_prod="$(parse_unix_md "$unix_md_raw" "production")"
  upstream_nfb="$(parse_unix_md "$unix_md_raw" "new_feature")"
  cdn_latest="$(parse_latest_txt "$cdn_latest_raw")"
  cdn_edge="$(parse_cdn_listing "$cdn_index_raw")"
  forum_topic="$(parse_forum_rss "$forum_rss_raw")"

  # 4. JSON Output
  if [[ $output_json -eq 1 ]]; then
    if command -v jq >/dev/null 2>&1; then
      jq -n \
        --arg ninja_pin "$ninja_pin" \
        --arg nix_stable_prod "$nix_stable_prod" \
        --arg nix_stable_latest "$nix_stable_latest" \
        --arg nix_unstable_prod "$nix_unstable_prod" \
        --arg nix_unstable_latest "$nix_unstable_latest" \
        --arg upstream_prod "$upstream_prod" \
        --arg upstream_nfb "$upstream_nfb" \
        --arg cdn_latest "$cdn_latest" \
        --arg cdn_edge "$cdn_edge" \
        --arg forum_topic "$forum_topic" \
        '{
          ninja_host: { pinned: $ninja_pin },
          nixpkgs: {
            stable: { production: $nix_stable_prod, latest: $nix_stable_latest },
            unstable: { production: $nix_unstable_prod, latest: $nix_unstable_latest }
          },
          upstream: {
            production: $upstream_prod,
            new_feature: $upstream_nfb,
            cdn_latest_txt: $cdn_latest,
            cdn_highest: $cdn_edge,
            forum_recent: $forum_topic
          }
        }'
    else
      printf '{"ninja_pin":"%s","upstream_prod":"%s","upstream_nfb":"%s","cdn_latest":"%s","cdn_edge":"%s"}\n' \
        "$ninja_pin" "$upstream_prod" "$upstream_nfb" "$cdn_latest" "$cdn_edge"
    fi
    return 0
  fi

  # 5. Formatted ANSI Table Output
  printf '%b%-26s %-16s %-32s%b\n' "$BOLD" "SOURCE / CHANNEL" "VERSION" "NOTES" "$NC"
  printf '%b%-26s %-16s %-32s%b\n' "$DIM" "--------------------------" "----------------" "--------------------------------" "$NC"
  printf '%b%-26s%b %b%-16s%b %-32s\n' "$GREEN" "Host (ninja/nvidia.nix)" "$NC" "$BOLD" "$ninja_pin" "$NC" "Current local pinned driver"
  printf '%b%-26s%b %-16s %-32s\n' "$BLUE" "Nixpkgs Stable (Prod)" "$NC" "$nix_stable_prod" "Flake input: nixpkgs"
  printf '%b%-26s%b %-16s %-32s\n' "$BLUE" "Nixpkgs Stable (Latest)" "$NC" "$nix_stable_latest" "Flake input: nixpkgs"
  printf '%b%-26s%b %-16s %-32s\n' "$CYAN" "Nixpkgs Unstable (Prod)" "$NC" "$nix_unstable_prod" "Flake input: nixpkgs-unstable"
  printf '%b%-26s%b %-16s %-32s\n' "$CYAN" "Nixpkgs Unstable (Latest)" "$NC" "$nix_unstable_latest" "Flake input: nixpkgs-unstable"
  printf '%b%-26s%b %-16s %-32s\n' "$YELLOW" "Upstream Production" "$NC" "$upstream_prod" "NVIDIA unix.md archive"
  printf '%b%-26s%b %-16s %-32s\n' "$YELLOW" "Upstream New Feature" "$NC" "$upstream_nfb" "NVIDIA unix.md archive"
  printf '%-26s %-16s %-32s\n' "Upstream CDN latest.txt" "$cdn_latest" "download.nvidia.com pointer"
  printf '%-26s %-16s %-32s\n' "Upstream CDN Highest" "$cdn_edge" "Highest tag on download CDN"
  printf '%-26s %-16s %-32s\n' "Upstream Forum Buzz" "$forum_topic" "Latest release feedback thread"
}

# Only execute main when invoked directly, not when sourced in tests
if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  run_nvidia_check "$@"
fi
