{ pkgs, userConfig, config, ... }:

{
  environment.systemPackages = with pkgs; [
    nh
    nvd
    nix-output-monitor # Used by nh for the pretty graphs
    gparted
  ];

  environment.sessionVariables = {
    # Define flake location for nh to avoid typing it explicitly
    # Path sourced from git config in home/dev.nix
    NH_FLAKE = "${userConfig.dotfilesDir}";
  };

  services.fwupd = {
    enable = true;
    daemonSettings = {
      EspLocation = config.boot.loader.efi.efiSysMountPoint;
      
      # STRATEGY: Core System Updates Only
      # Peripheral and non-essential plugins are disabled to prevent the daemon 
      # from hanging during hardware probes (specifically problematic with some 
      # USB headsets/controllers).
      #
      # ENABLED (Implicitly): 
      # - uefi_capsule/dbx: Motherboard BIOS and Secure Boot security updates
      # - nvme: SSD firmware updates (Crucial T705 / WD SN850X)
      # - cpu/pci_psp: AMD Microcode and Secure Processor updates
      # - tpm: Trusted Platform Module updates
      
      DisabledPlugins = [ 
        "msr" "test" "invalid" "modem_manager" "jabra" "jabra_file" "steelseries" 
        "corsair" "logitech_hidpp" "thunderbolt" "upower" "analogix" "android_boot" 
        "asus_hid" "aver_hid" "bcm57xx" "bnr_dp" "ccgx" "ccgx_dmc" "cfu" "ch341a" 
        "ch347" "cros_ec" "dell_dock" "dell_kestrel" "devlink" "dfu" "ebitdo" 
        "egis_moc" "elan_kbd" "elanfp" "elantp" "emmc" "ep963x" "fastboot" "focalfp" 
        "fpc" "framework_qmk" "fresco_pd" "genesys" "genesys_gl32xx" "goodix_moc" 
        "goodixtp" "gpio" "hpi_cfu" "huddly_usb" "hughski_colorhug" "igsc" "ilitek_its" 
        "intel_amt" "intel_cvs" "intel_mchi" "intel_mkhi" "intel_usb4" "kinetic_dp" 
        "legion_hid2" "linux_display" "logitech_bulkcontroller" "logitech_rallysystem" 
        "logitech_scribe" "logitech_tap" "mediatek_scaler" "parade_lspcon" "parade_usbhub" 
        "pci_bcr" "pixart_rf" "qc_firehose" "qc_s5gen2" "qsi_dock" "realtek_mst" 
        "rp_pico" "rts54hub" "synaptics_cape" "synaptics_cxaudio" "synaptics_mst" 
        "synaptics_prometheus" "synaptics_rmi" "synaptics_vmm9" "system76_launch" 
        "telink_dfu" "thelio_io" "ti_tps6598x" "usi_dock" "vli" "wacom_raw" 
        "wacom_usb" "wistron_dock"
      ];
    };
  };

  systemd.services.fwupd.serviceConfig = {
    TimeoutStartSec = 180;
  };
}
