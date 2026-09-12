#!/usr/bin/env bash
# Fixture-based unit tests for scripts/nvidia-check.sh pure parsing functions.
#
# Runs offline — no network requests, no nix daemon. Sourced deterministically.

set -uo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
NVIDIA_CHECK=$SCRIPT_DIR/../nvidia-check.sh

if [[ ! -f $NVIDIA_CHECK ]]; then
  printf 'nvidia-check.sh not found at %s\n' "$NVIDIA_CHECK" >&2
  exit 1
fi

# Source functions without executing main
# shellcheck source=/dev/null
source "$NVIDIA_CHECK"
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

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

fixture_unix_md='
**Linux x86_64/AMD64/EM64T**  
 Latest Production Branch Version: [595.91.07](https://www.nvidia.com/en-us/drivers/details/277699.md)  
 Latest New Feature Branch Version: [610.57.04](https://www.nvidia.com/en-us/drivers/details/274513.md)  
 Latest Legacy GPU version (470.xx series): [470.256.02](https://www.nvidia.com/en-us/drivers/details/226760.md)  
'

fixture_unix_md_plain='
**Linux x86_64**
Latest Production Branch Version: 590.20.01
Latest New Feature Branch Version: 600.10
'

fixture_latest_txt='595.99.02 595.99.02/NVIDIA-Linux-x86_64-595.99.02.run'

fixture_cdn_html='
<!doctype html>
<html>
<body>
  <li><a href="595.80/">595.80/</a></li>
  <li><a href="595.99.02/">595.99.02/</a></li>
  <li><a href="610.57.04/">610.57.04/</a></li>
  <li><a href="615.71.09/">615.71.09/</a></li>
  <li><a href="README/">README/</a></li>
</body>
</html>
'

fixture_cdn_html_single_quotes="
<li><a href='550.54.14/'>550.54.14/</a></li>
<li><a href='615.71.09/'>615.71.09/</a></li>
"

fixture_forum_rss='
<?xml version="1.0" encoding="UTF-8" ?>
<rss version="2.0">
  <channel>
    <title>Linux - NVIDIA Developer Forums</title>
    <item>
      <title>Display freezes seemingly randomly on NixOS KDE Plamsa</title>
    </item>
    <item>
      <title>615 release feedback &amp; discussion</title>
      <description>615.71.09 driver feedback</description>
    </item>
  </channel>
</rss>
'

# ---------------------------------------------------------------------------
# Test Suite
# ---------------------------------------------------------------------------

section "parse_unix_md"
assert_eq "production branch with markdown link" "595.91.07" "$(parse_unix_md "$fixture_unix_md" "production")"
assert_eq "new feature branch with markdown link" "610.57.04" "$(parse_unix_md "$fixture_unix_md" "new_feature")"
assert_eq "production branch plain text" "590.20.01" "$(parse_unix_md "$fixture_unix_md_plain" "production")"
assert_eq "new feature branch plain text" "600.10" "$(parse_unix_md "$fixture_unix_md_plain" "new_feature")"
assert_eq "missing content returns n/a" "n/a" "$(parse_unix_md "" "production")"

section "parse_latest_txt"
assert_eq "extracts first word from latest.txt" "595.99.02" "$(parse_latest_txt "$fixture_latest_txt")"
assert_eq "invalid content returns n/a" "n/a" "$(parse_latest_txt "not-a-version")"
assert_eq "empty content returns n/a" "n/a" "$(parse_latest_txt "")"

section "parse_cdn_listing"
assert_eq "picks highest semver from double-quoted html" "615.71.09" "$(parse_cdn_listing "$fixture_cdn_html")"
assert_eq "picks highest semver from single-quoted html" "615.71.09" "$(parse_cdn_listing "$fixture_cdn_html_single_quotes")"
assert_eq "empty listing returns n/a" "n/a" "$(parse_cdn_listing "")"

section "parse_forum_rss"
assert_eq "extracts release feedback thread title" "615 release feedback & discussion" "$(parse_forum_rss "$fixture_forum_rss")"
assert_eq "empty rss returns n/a" "n/a" "$(parse_forum_rss "")"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

printf '\n------------------------------------------------------------\n'
printf 'Passed: %d   Failed: %d\n' "$pass" "$fail"

if ((fail > 0)); then
  printf '\nFailures:\n'
  for f in "${fail_list[@]}"; do
    printf '  - %s\n' "$f"
  done
  exit 1
fi

exit 0
