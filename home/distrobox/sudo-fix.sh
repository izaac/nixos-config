#!/bin/sh
SUDO_BIN="${HOME}/.local/share/distrobox/bin/sudo"
mkdir -p "$(dirname "$SUDO_BIN")"
cat >"$SUDO_BIN" <<'WRAPPER'
#!/bin/sh
# Use whichever container runtime distrobox picked (podman or docker).
RUNTIME="${DBX_CONTAINER_MANAGER:-}"
if [ -z "$RUNTIME" ]; then
  if command -v podman >/dev/null 2>&1; then
    RUNTIME=podman
  elif command -v docker >/dev/null 2>&1; then
    RUNTIME=docker
  else
    echo "sudo-fix: no podman or docker on host" >&2
    exit 1
  fi
fi
exec distrobox-host-exec "$RUNTIME" exec -it -u root "$CONTAINER_ID" "$@"
WRAPPER
chmod +x "$SUDO_BIN"
