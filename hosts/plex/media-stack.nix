# plex: media acquisition and library stack.
#
# Layout, in the order data flows:
#
#   1. Torrents. Gluetun holds the only VPN namespace; qBittorrent has no
#      network of its own and shares gluetun's with --network=container:gluetun.
#      That is why 8080 is published on gluetun rather than qBittorrent: the
#      WebUI port is forwarded from the container that owns the namespace, and
#      a leak would have to happen inside gluetun's netns, not qBittorrent's.
#      Completed torrents land in /var/lib/media-staging/torrents.
#
#   2. Local staging. Arr services (native, not containerised) import finished
#      downloads and hardlink or move them into /var/lib/media-staging/local,
#      which is a real directory on the root SSD.
#
#   3. Union. mergerfs presents /var/lib/media-staging/local (fast, small,
#      local) followed by /srv/media-remote (rclone ul-crypt mount, large,
#      network) as the single tree /srv/media. Category create policy is ff
#      (first found, for files) so new writes stay local and only reads of
#      already-uploaded media go over the network. Plex reads /srv/media only.
#
#   4. Mover. media-mover.service drains /var/lib/media-staging/local to
#      ul-crypt: every 30 minutes, rate limited so it cannot saturate the
#      uplink, then refreshes rclone's VFS listing cache so Plex sees the files
#      that just left the local branch.
#
# The mount order matters: mergerfs needs the rclone mount up first, and Plex
# needs mergerfs up first, otherwise it starts against an empty /srv/media and
# prunes library entries.
{
  lib,
  pkgs,
  userConfig,
  ...
}: let
  staging = "/var/lib/media-staging";
  stagingLocal = "${staging}/local";
  stagingTorrents = "${staging}/torrents";
  remoteMount = "/srv/media-remote";
  library = "/srv/media";

  # Rendered as a single tmpfiles line, so newlines have to be literal `\n`
  # escapes. `f` only writes the file when it is missing, so a real WireGuard
  # key pasted in later survives reboots; the template exists so the file has
  # the right mode and owner from the start.
  gluetunEnv = lib.concatStringsSep "\\n" [
    "# ProtonVPN WireGuard configuration for Gluetun (local host only)"
    "VPN_SERVICE_PROVIDER=protonvpn"
    "VPN_TYPE=wireguard"
    "WIREGUARD_PRIVATE_KEY="
    "# Optional: specify server country/city or port forwarding"
    "# SERVER_COUNTRIES=United States"
    "# SERVER_CITIES="
    "# VPN_PORT_FORWARDING=on"
  ];
in {
  # Containers. Podman is the backend; docker stays disabled.
  # Netavark must use nftables directly to avoid iptables-nft conflicts with Tailscale.
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman";
  virtualisation.containers.containersConf.settings.network.firewall_driver = "nftables";

  virtualisation.oci-containers.containers = {
    gluetun = {
      image = "docker.io/qmcgaw/gluetun:latest";
      environmentFiles = ["/var/lib/gluetun/gluetun.env"];
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--device=/dev/net/tun:/dev/net/tun"
      ];
      ports = [
        "8080:8080" # qBittorrent WebUI
      ];
    };

    # No ports and no network of its own: it lives in gluetun's namespace, so
    # anything it binds is only reachable through gluetun's published ports.
    qbittorrent = {
      image = "lscr.io/linuxserver/qbittorrent:latest";
      dependsOn = ["gluetun"];
      extraOptions = [
        "--network=container:gluetun"
      ];
      environment = {
        PUID = "1000";
        PGID = "100";
        TZ = "UTC";
        WEBUI_PORT = "8080";
        TORRENTING_PORT = "6881";
      };
      volumes = [
        "/var/lib/qbittorrent:/config"
        "${stagingTorrents}:/downloads"
      ];
    };

    # FlareSolverr: proxy service to bypass Cloudflare protection on indexers.
    flaresolverr = {
      image = "ghcr.io/flaresolverr/flaresolverr:latest";
      ports = [
        "8191:8191"
      ];
      environment = {
        LOG_LEVEL = "info";
        TZ = "UTC";
      };
    };
  };

  # Arr services run natively rather than in containers: they only need to move
  # files around the staging tree, and native units keep the same UID as Plex
  # so hardlinks and permissions line up without PUID/PGID guesswork.
  services.sonarr = {
    enable = true;
    user = userConfig.username;
    group = "users";
    openFirewall = true;
  };

  services.radarr = {
    enable = true;
    user = userConfig.username;
    group = "users";
    openFirewall = true;
  };

  services.prowlarr = {
    enable = true;
    openFirewall = true;
  };

  # Staging and mount points. `TV\x20Shows` is tmpfiles' escape for the space in
  # the directory name; both Arrs are pointed at it by hand in their own UI.
  systemd.tmpfiles.rules = [
    "d ${staging} 0775 ${userConfig.username} users -"
    "d ${stagingTorrents} 0775 ${userConfig.username} users -"
    "d ${stagingLocal} 0775 ${userConfig.username} users -"
    "d ${stagingLocal}/movies 0775 ${userConfig.username} users -"
    "d ${stagingLocal}/tvshows 0775 ${userConfig.username} users -"
    "d ${remoteMount} 0775 ${userConfig.username} users -"
    "d ${library} 0775 ${userConfig.username} users -"
    "d /var/lib/gluetun 0700 root root -"
    "d /var/lib/qbittorrent 0775 ${userConfig.username} users -"
    "f /var/lib/gluetun/gluetun.env 0600 root root - ${gluetunEnv}"
  ];

  # mergerfs union: local staging branch first, remote rclone branch second.
  # Both branches must exist before the mount, which is what the tmpfiles rules
  # above and the rclone unit ordering take care of.
  systemd.services.mergerfs-media = {
    description = "Mergerfs union mount for /srv/media";
    after = ["rclone-ul-crypt.service"];
    wants = ["rclone-ul-crypt.service"];
    requires = ["rclone-ul-crypt.service"];
    bindsTo = ["rclone-ul-crypt.service"];
    partOf = ["rclone-ul-crypt.service"];
    wantedBy = ["multi-user.target"];
    path = [pkgs.mergerfs pkgs.fuse3 "/run/wrappers"];
    serviceConfig = {
      Type = "forking";
      ExecStart = "${pkgs.mergerfs}/bin/mergerfs -o allow_other,use_ino,cache.files=partial,dropcacheonclose=true,category.create=ff ${stagingLocal}:${remoteMount} ${library}";
      ExecStop = "/run/current-system/sw/bin/umount -l ${library}";
      Restart = "on-failure";
      RestartSec = "10s";
    };
  };

  # Plex must not start before the union is mounted, or it scans an empty
  # library and starts removing entries. If the mount disappears, Plex stops.
  systemd.services.plex.after = ["mergerfs-media.service"];
  systemd.services.plex.requires = ["mergerfs-media.service"];
  systemd.services.plex.bindsTo = ["mergerfs-media.service"];
  systemd.services.plex.partOf = ["mergerfs-media.service"];

  # Background mover. Uploads whatever the Arrs staged locally, then tells
  # rclone to drop cached listings so Plex finds the files in their new home.
  systemd.services.media-mover = {
    description = "Move staged media from local staging to ul-crypt";
    after = ["rclone-ul-crypt.service" "mergerfs-media.service"];
    wants = ["mergerfs-media.service"];
    requires = ["rclone-ul-crypt.service"];
    # A oneshot unit cannot overlap itself: systemd refuses to start a unit that
    # is already active, so the timer firing mid-move is a no-op rather than a
    # second mover fighting over the same files.
    serviceConfig = {
      Type = "oneshot";
      User = userConfig.username;
      Group = "users";
    };
    script = ''
      set -eu

      # Nothing settled: skip before touching the remote at all. Files must be
      # at least 15 minutes old to ensure Sonarr/Radarr finished importing them.
      if [ -z "$(${pkgs.findutils}/bin/find ${stagingLocal} -type f -mmin +15 -print -quit)" ]; then
        echo "media-mover: no settled files (>=15m old) staged in ${stagingLocal}"
        exit 0
      fi

      # The refresh at the end needs rclone's control socket. Uploading without
      # it would still work, but Plex would not see the files until the 72h
      # directory cache expired, so a dead socket counts as a retryable failure.
      if ! ${pkgs.rclone}/bin/rclone rc --rc-addr 127.0.0.1:5572 --rc-no-auth core/version > /dev/null 2>&1; then
        echo "media-mover: rclone rc socket not answering on 127.0.0.1:5572" >&2
        exit 1
      fi

      ${pkgs.rclone}/bin/rclone move ${stagingLocal}/ ul-crypt: \
        --config /home/${userConfig.username}/.config/rclone/rclone.conf \
        --min-age 15m \
        --delete-empty-src-dirs \
        --transfers 1 \
        --checkers 2 \
        --check-first \
        --bwlimit 2.5M \
        --log-level NOTICE

      ${pkgs.rclone}/bin/rclone rc --rc-addr 127.0.0.1:5572 --rc-no-auth vfs/refresh recursive=true
    '';
  };

  systemd.timers.media-mover = {
    description = "Periodically drain local media staging to ul-crypt";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*:0/30";
      Persistent = true;
    };
  };

  environment.systemPackages = [pkgs.mergerfs];

  # qBittorrent WebUI (8080) and FlareSolverr proxy (8191).
  networking.firewall.allowedTCPPorts = [8080 8191];
}
