{
  config,
  lib,
  ...
}: let
  cfg = config.mySystem.core.printing;
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
        default = "192.168.0.147";
        description = "IP address of the Canon LBP113/LBP913 on the LAN.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # CUPS print server. The Canon LBP113/LBP913 is an IPP-Everywhere
    # (driverless / AirPrint) laser, so no vendor driver is required.
    services.printing.enable = true;

    # mDNS/DNS-SD so the network printer is discoverable.
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # Declaratively register the printer with the driverless "everywhere"
    # model. This gives the full filter chain (any input format -> printer)
    # plus paper-size/duplex options in the print dialog.
    #
    # NOTE: the printer's RTC must be set to a UTC/GMT (+00:00) time zone.
    # On a non-zero offset its firmware emits a malformed
    # `printer-config-change-date-time` (offset minutes = 164, out of the
    # RFC 8011 5.1.15 range), which makes CUPS reject queue creation with
    # "Bad dateTime UTC minutes 164". UTC keeps the offset at "Z" and valid.
    hardware.printers = lib.mkIf cfg.networkPrinter.enable {
      ensureDefaultPrinter = cfg.networkPrinter.name;
      ensurePrinters = [
        {
          name = cfg.networkPrinter.name;
          description = "Canon LBP113/LBP913 (network)";
          location = "LAN";
          deviceUri = "ipp://${cfg.networkPrinter.address}/ipp/print";
          model = "everywhere";
        }
      ];
    };
  };
}
