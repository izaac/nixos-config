# Transmission VPN Setup & Management

Containerized Transmission client running behind a WireGuard VPN tunnel with a modern web UI,
rootless Podman execution, and on-demand lifecycle controls.

---

## Architecture Overview

- **Container Image**: `magicalyak/transmissionvpn:latest`
- **Runtime**: Rootless Podman with `docker-compose`
- **VPN Protocol**: WireGuard (tunnel client built into the container)
- **Web UI**: Flood for Transmission (`http://localhost:9091`)
- **Lifecycle Mode**: On-demand user service via systemd

---

## Directory Structure & Default Paths

The service expects local configuration under `${HOME}/services/transmissionvpn`:

```text
${HOME}/services/transmissionvpn/
├── docker-compose.yml       # Compose specification
├── config/
│   ├── web-ui/
│   │   └── flood/           # Flood web UI assets
│   └── wireguard/
│       └── wg0.conf         # WireGuard VPN configuration (private key stays local)
└── watch/                   # Optional watch directory
```

> **Privacy Notice**: Configuration files containing private keys, credentials, or sensitive network
> mappings remain outside git tracking. Only the systemd unit and desktop launcher declarations are
> committed in `nixos-config`.

---

## NixOS Configuration

The service is declared in `home/transmission-vpn.nix` and conditionally enabled when Podman
virtualization is enabled (`osConfig.virtualisation.podman.enable`):

1. **Systemd User Unit (`systemd.user.services.transmissionvpn`)**:
   - Guarded with
     `ConditionPathExists = "${config.home.homeDirectory}/services/transmissionvpn/docker-compose.yml"`.
   - Requires `podman.socket` and waits for `network-online.target`.
   - On-demand configuration (`WantedBy = []`), avoiding autostart on boot.
   - Executes compose via Nix-managed `pkgs.docker-compose`.

2. **Launcher Script (`transmission-vpn`)**:
   - Starts the user service via `systemctl --user start transmissionvpn.service`.
   - Opens the web interface in the default browser at `http://localhost:9091`.

3. **Desktop Entry (`transmission-vpn.desktop`)**:
   - Provides an application launcher entry in desktop menus.
   - Includes a desktop action to stop the service cleanly:
     `systemctl --user stop transmissionvpn.service`.

---

## Local Compose Setup (`docker-compose.yml`)

A sample template for `${HOME}/services/transmissionvpn/docker-compose.yml`:

```yaml
services:
  transmissionvpn:
    image: magicalyak/transmissionvpn:latest
    pull_policy: missing
    container_name: transmissionvpn
    cap_add:
      - NET_ADMIN
      - NET_RAW
    devices:
      - /dev/net/tun:/dev/net/tun
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    ports:
      - "9091:9091"
    volumes:
      - ./config:/config
      - ${HOME}/Downloads/torrents:/downloads
      - ./watch:/watch
    environment:
      - VPN_CLIENT=wireguard
      - VPN_CONFIG=/config/wireguard/wg0.conf
      - NAME_SERVERS=10.2.0.1
      - TRANSMISSION_WEB_HOME=/config/web-ui/flood
      - TRANSMISSION_WEB_UI_AUTO=flood
      - LAN_NETWORK=192.168.0.0/24
      - PUID=1000
      - PGID=100
      - TZ=UTC
    restart: unless-stopped
```

### Key Parameters:

- `pull_policy: missing`: Prevents startup delays or failures if the external registry is
  unreachable when launching offline or before external DNS is resolved.
- `NET_RAW`: Required in rootless containers to allow internal health check ICMP probes.
- `LAN_NETWORK`: Restricts Web UI access to the designated local subnet while routing all BitTorrent
  traffic strictly through the VPN tunnel.

---

## Usage Commands

- **Launch on demand**:

  ```bash
  transmission-vpn
  ```

  Or select **Transmission VPN** from the application menu (Niri / Ashell / fuzzel).

- **Stop service**:

  ```bash
  systemctl --user stop transmissionvpn.service
  ```

  Or right-click the desktop launcher and select **Stop Transmission VPN**.

- **Check status**:

  ```bash
  systemctl --user status transmissionvpn.service
  podman ps
  ```

---

## Managing Web UIs (Flood, Combustion, etc.)

Alternative web UIs live in `${HOME}/services/transmissionvpn/config/web-ui/<ui-name>/`.

### 1. Adding a New Web UI

1. Download and extract the web UI assets into a temporary directory.
2. Copy the files into the config directory and set rootless container permissions (`1000:100`):

```bash
mkdir -p /tmp/new-ui
# Example: downloading Combustion release
curl -sL "https://github.com/secretmapper/combustion/archive/refs/heads/release.zip" -o /tmp/new-ui.zip
unzip -q -o /tmp/new-ui.zip -d /tmp/new-ui/

# Install into container web-ui directory
podman unshare mkdir -p "${HOME}/services/transmissionvpn/config/web-ui/combustion"
podman unshare cp -r /tmp/new-ui/combustion-release/* "${HOME}/services/transmissionvpn/config/web-ui/combustion/"
podman unshare chown -R 1000:100 "${HOME}/services/transmissionvpn/config/web-ui/combustion"
rm -rf /tmp/new-ui /tmp/new-ui.zip
```

### 2. Switching the Active Web UI

Edit `${HOME}/services/transmissionvpn/docker-compose.yml` to point to the desired UI directory:

```yaml
environment:
  - TRANSMISSION_WEB_HOME=/config/web-ui/combustion
  - TRANSMISSION_WEB_UI_AUTO=combustion
```

### 3. Activating Changes

You do not need to restart the Podman daemon or socket. Simply restart the user systemd service to
recreate the container with the updated environment:

```bash
systemctl --user restart transmissionvpn.service
```

### 4. Updating an Existing Web UI

To update an existing UI (such as Flood):

1. Download the latest release zip.
2. Overwrite the files in `${HOME}/services/transmissionvpn/config/web-ui/<ui-name>/` and re-assert
   container ownership:

```bash
mkdir -p /tmp/flood-update
curl -sL "https://github.com/johman10/flood-for-transmission/releases/latest/download/flood-for-transmission.zip" -o /tmp/flood-update.zip
unzip -q -o /tmp/flood-update.zip -d /tmp/flood-update/

podman unshare cp -r /tmp/flood-update/* "${HOME}/services/transmissionvpn/config/web-ui/flood/"
podman unshare chown -R 1000:100 "${HOME}/services/transmissionvpn/config/web-ui/flood"
rm -rf /tmp/flood-update /tmp/flood-update.zip
```

Finally, hard refresh your browser (`Ctrl+Shift+R`) to clear cached web assets, or restart the
container via `systemctl --user restart transmissionvpn.service`.
