{
  config,
  lib,
  pkgs,
  siteConfig,
  ...
}: let
  cfg = config.mySystem.core.printing;

  # Static IPP-Everywhere PPD for the Canon LBP113/LBP913, generated once with
  # `lpadmin -m everywhere` and pinned here. Packaging it into the CUPS model
  # directory lets us reference it by name without a live network query at
  # boot, which sidesteps the upstream race where queue creation fails if the
  # printer is asleep/offline (NixOS/nixpkgs#78535).
  canonLbp113Ppd = pkgs.runCommand "canon-lbp113-ppd" {} ''
    install -Dm644 ${./printers/Canon_LBP113.ppd} \
      "$out/share/cups/model/Canon_LBP113.ppd"
  '';
in {
  options.mySystem.core.printing = {
    enable = lib.mkEnableOption "Core printing (CUPS) configuration";

    networkPrinter = {
      enable = lib.mkEnableOption "Declaratively provision the Canon LBP113/LBP913 network printer";

      name = lib.mkOption {
        type = lib.types.str;
        default = "Canon_LBP113";
        description = "CUPS queue name for the printer.";
      };

      address = lib.mkOption {
        type = lib.types.str;
        default = siteConfig.printerIp;
        description = "IP address of the Canon LBP113/LBP913 on the LAN.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # CUPS print server. The pinned PPD is registered as a CUPS driver so the
    # declarative queue can reference it by filename.
    services.printing = {
      enable = true;
      drivers = lib.mkIf cfg.networkPrinter.enable [canonLbp113Ppd];
    };

    # mDNS/DNS-SD so the network printer is discoverable.
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # Declaratively register the printer using the pinned static PPD.
    #
    # NOTE: the printer's RTC must use a UTC (+00:00) time zone. On a non-zero
    # offset its firmware emits a malformed printer-config-change-date-time
    # (offset minutes 164, out of RFC 8011 5.1.15 range). UTC keeps the offset
    # at "Z" and valid; otherwise IPP queries and printing fail.
    hardware.printers = lib.mkIf cfg.networkPrinter.enable {
      ensureDefaultPrinter = cfg.networkPrinter.name;
      ensurePrinters = [
        {
          name = cfg.networkPrinter.name;
          description = "Canon LBP113/LBP913 (network)";
          location = "LAN";
          deviceUri = "ipp://${cfg.networkPrinter.address}/ipp/print";
          model = "Canon_LBP113.ppd";
        }
      ];
    };
  };
}
