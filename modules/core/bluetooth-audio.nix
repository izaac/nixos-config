{ pkgs, ... }:

{
  # Enable high-quality Bluetooth codecs
  environment.systemPackages = with pkgs; [
    # A generic "all-codecs" library often helps wireplumber find them
    # But mostly it relies on pipewire's internal implementation
  ];

  services.pipewire = {
    wireplumber.enable = true;
    wireplumber.extraConfig = {
      "10-bluez" = {
        "monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.headset-roles" = [ "hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag" ];
          "bluez5.roles" = [ "a2dp_sink" "a2dp_source" "hfp_hf" "hfp_ag" "hsp_hs" "hsp_ag" ];
          "bluez5.hfphsp-backend" = "native";
          
          # Priority: LDAC > AptX HD > AptX > AAC > SBC
          "bluez5.codecs" = [ "ldac" "aptx_hd" "aptx" "aac" "sbc_xq" "sbc" ];
        };
      };
      
      # Disable auto-switching to headset profile (HSP/HFP) for microphone use
      # Prevents audio quality degradation (fallback to low-bandwidth profiles) when applications access the microphone
      "11-bluetooth-policy" = {
        "wireplumber.settings" = {
          "bluetooth.autoswitch-to-headset-profile" = false;
        };
      };
    };
  };
  
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    disabledPlugins = [ "bap" "sap" ];
    settings = {
      General = {
        Enable = "Source,Sink,Media";
        # MultiProfile ensures simultaneous support for multiple Bluetooth profiles (e.g. A2DP + HFP)
        MultiProfile = "multiple";
        # Force dual mode to ensure compatibility with both LE and Classic devices
        ControllerMode = "dual";
        # Faster connection/pairing for desktops (slightly more power, but better UX)
        FastConnectable = true;
        # Better handling of repairing for some headsets
        JustWorksRepairing = "always";
        # Enables battery reporting and other experimental features
        Experimental = true;
        # Prevents the adapter from powering down too quickly
        IdleTimeout = 0;
        # Reconnection timeout
        AutoConnectTimeout = 180;
        # Better HID support for modern headsets (e.g. Sony WH series)
        UserspaceHID = true;
      };
    };
  };
}
