{
  config,
  pkgs,
  lib,
  osConfig ? {},
  ...
}: let
  launchTransmission = pkgs.writeShellScriptBin "transmission-vpn" ''
    systemctl --user start transmissionvpn.service
    exec xdg-open http://localhost:9091
  '';
in
  # Transmission container behind WireGuard VPN.
  # Expects local compose setup at ~/services/transmissionvpn
  # with WireGuard configuration kept locally at config/wireguard/wg0.conf.
  lib.mkIf (osConfig.virtualisation.podman.enable or false) {
    home.packages = [launchTransmission];

    systemd.user.services.transmissionvpn = {
      Unit = {
        Description = "Transmission VPN";
        After = ["network-online.target" "podman.socket"];
        Requires = ["podman.socket"];
        ConditionPathExists = "${config.home.homeDirectory}/services/transmissionvpn/docker-compose.yml";
      };
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        WorkingDirectory = "${config.home.homeDirectory}/services/transmissionvpn";
        ExecStart = "${pkgs.docker-compose}/bin/docker-compose up -d";
        ExecStop = "${pkgs.docker-compose}/bin/docker-compose down";
      };
      Install = {
        # On-demand only: not started at boot
        WantedBy = [];
      };
    };

    xdg.desktopEntries.transmission-vpn = {
      name = "Transmission VPN";
      genericName = "BitTorrent Client";
      comment = "Secure BitTorrent Client";
      exec = "${launchTransmission}/bin/transmission-vpn";
      icon = "transmission";
      terminal = false;
      categories = [
        "Network"
        "FileTransfer"
        "P2P"
      ];
      actions = {
        "stop" = {
          name = "Stop Transmission VPN";
          exec = "systemctl --user stop transmissionvpn.service";
        };
      };
    };
  }
