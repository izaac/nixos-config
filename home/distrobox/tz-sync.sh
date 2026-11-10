#!/bin/sh
Z=$(readlink /run/host/etc/localtime 2>/dev/null | sed 's#.*/zoneinfo/##')
[ -z "$Z" ] && [ -f /run/host/etc/timezone ] && Z=$(cat /run/host/etc/timezone)
if [ -n "$Z" ] && [ -f "/usr/share/zoneinfo/$Z" ]; then
  sudo ln -sf "/usr/share/zoneinfo/$Z" /etc/localtime
  echo "$Z" | sudo tee /etc/timezone >/dev/null 2>&1 || true
fi
exit 0
