{ pkgs, ... }:

{
  # 1. Hardware Quirks
  # DJI Mic Mini (g) & Razer Kiyo Pro (k)
  boot.kernelParams = [
    "usbcore.quirks=2ca3:4011:g"
    "usbcore.quirks=1532:0e05:k"
  ];

  # 2. Block Razer Kiyo Pro Audio (Initrd)
  # Prevents the webcam from claiming a sound card slot during early boot.
  boot.initrd.services.udev.rules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1532", ATTRS{idProduct}=="0e05", ATTR{bInterfaceClass}=="01", ATTR{authorized}="0"
  '';

  # 3. Audio Driver Options
  # skip_validation=1 : Fixes DJI "cannot find UAC_HEADER" (Error -22).
  # ignore_ctl_error=1: Prevents mixer crashes on non-standard devices.
  # device_setup=1    : Forces initialization (Essential for DJI Receiver).
  boot.extraModprobeConfig = ''
    options snd-usb-audio skip_validation=1 ignore_ctl_error=1 device_setup=1
  '';

  # 4. Force DJI Mic Binding (Auto-Bind)
  # The DJI Mic reports a Vendor-Specific Class (0xff), so the driver ignores it
  # by default. This rule forces the bind immediately upon connection.
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ACTION=="add", ATTRS{idVendor}=="2ca3", ATTRS{idProduct}=="4011", RUN+="/bin/sh -c '/run/current-system/sw/bin/modprobe snd-usb-audio; echo 2ca3 4011 > /sys/bus/usb/drivers/snd-usb-audio/new_id'"
  '';

  # 5. Ensure Audio Module Availability
  boot.kernelModules = [ ];
}
