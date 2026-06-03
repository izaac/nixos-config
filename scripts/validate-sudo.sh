#!/usr/bin/env bash
# Validate the sudo-readonly hardening, accurately and without executing
# anything as root.
#
# Why not `sudo -nl <cmd>`? izaac is in the wheel group, which carries a
# blanket `(ALL:ALL) ALL` rule (password required). `sudo -l <cmd>` answers
# "is this command allowed AT ALL", so it returns 0 even for password-gated
# commands. It cannot distinguish NOPASSWD from password-required.
#
# Accurate method: the per-command paths only ever appear in `sudo -ln`
# output because of the NOPASSWD readonly rule. The wheel ALL rule does not
# enumerate paths. So a command is passwordless IFF its store path shows up
# in `sudo -ln`. Pure text check, nothing runs as root.
set -u

# sudo-rs canonicalizes symlinks, so policy listing shows the resolved nix
# store path (/nix/store/...-pkg/bin/<cmd>), not /run/current-system/sw/bin.
# Match by the /bin/<cmd> suffix with a token boundary instead.
rules="$(sudo -ln 2>/dev/null)"

listed() { grep -Eq "/bin/$1([[:space:],]|\$)" <<<"$rules"; }

pass=0
fail=0

allow=(lspci lsusb lshw lsblk lsof blkid smartctl dmidecode ss nixos-option iotop)
deny=(nix nix-store systemctl journalctl ip nft cryptsetup nvme bootctl udevadm dmesg loginctl)

echo "== should be PASSWORDLESS (inert, listed under NOPASSWD) =="
for c in "${allow[@]}"; do
  if listed "$c"; then
    printf '  OK %-14s passwordless\n' "$c"
    pass=$((pass + 1))
  else
    printf '  XX %-14s NOT in NOPASSWD set (regressed)\n' "$c"
    fail=$((fail + 1))
  fi
done

echo
echo "== should REQUIRE password (absent from NOPASSWD set) =="
for c in "${deny[@]}"; do
  if listed "$c"; then
    printf '  XX %-14s STILL passwordless (HOLE)\n' "$c"
    fail=$((fail + 1))
  else
    printf '  OK %-14s requires password\n' "$c"
    pass=$((pass + 1))
  fi
done

echo
echo "== locked wrappers (should be passwordless via store path) =="
for w in journal-read nft-show; do
  if listed "$w"; then
    printf '  OK %-14s passwordless wrapper\n' "$w"
    pass=$((pass + 1))
  else
    printf '  XX %-14s wrapper missing\n' "$w"
    fail=$((fail + 1))
  fi
done

echo
echo "passed=$pass failed=$fail"
[ "$fail" -eq 0 ] && echo "ALL GOOD — hole shut, only inert tools + locked wrappers are passwordless" || echo "REVIEW NEEDED"
exit "$fail"
