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
  
  # Ensure the Bluetooth controller is optimized for audio
  hardware.bluetooth.settings = {
    General = {
      # MultiProfile ensures simultaneous support for multiple Bluetooth profiles (e.g. A2DP + HFP)
      # "bredr" vs "dual" logic is handled by defaults; focusing on profile availability here.
      MultiProfile = "multiple";
    };
  };
}
