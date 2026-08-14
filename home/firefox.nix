{
  config,
  lib,
  pkgs,
  osConfig ? {},
  ...
}: let
  prime = osConfig.hardware.nvidia.prime or {};

  # "PCI:0:2:0" -> "pci-0000:00:02.0", the form udev uses for /dev/dri/by-path.
  busPath = busId: let
    parts = lib.splitString ":" (lib.removePrefix "PCI:" busId);
    pad = lib.fixedWidthString 2 "0";
  in "pci-0000:${pad (builtins.elemAt parts 0)}:${pad (builtins.elemAt parts 1)}.${builtins.elemAt parts 2}";

  # Only hybrid laptops have a second GPU worth avoiding. Derived from the
  # PRIME bus id rather than hardcoded so it cannot drift from the host config.
  isHybrid = prime.offload.enable or false;
  igpuRenderNode = "/dev/dri/by-path/${busPath prime.intelBusId}-render";

  # Which JSON glvnd reads decides which EGL vendor gets loaded. The filename
  # ships with mesa ("50_mesa.json" today) rather than being a NixOS interface,
  # so glob for it and fail the build if it ever disappears, instead of quietly
  # writing a path that no longer exists and letting NVIDIA's vendor load again.
  # The library_path inside is absolute, so copying it out of the driver package
  # keeps working without /run/opengl-driver.
  mesaEglVendor =
    pkgs.runCommand "mesa-egl-vendor.json" {
      graphics = osConfig.hardware.graphics.package or pkgs.mesa;
    } ''
      json=$(ls "$graphics"/share/glvnd/egl_vendor.d/*mesa*.json 2>/dev/null | head -1)
      if [ -z "$json" ]; then
        echo "no mesa EGL vendor JSON under $graphics/share/glvnd/egl_vendor.d" >&2
        exit 1
      fi
      cp "$json" "$out"
    '';

  # Keep every Firefox process off the discrete GPU.
  #
  # MOZ_DRM_DEVICE alone is not enough. It only steers the VA-API decode
  # display; Firefox's EGL device display reads gfxVars::DrmRenderDevice()
  # directly, which comes from its glxtest probe and resolved to the dGPU. The
  # RDD process therefore still loaded libEGL_nvidia and held /dev/nvidia0,
  # /dev/nvidiactl and the dGPU render node open for the life of the browser.
  #
  # Those handles cost no power (the card still reached D3cold) but they break
  # system suspend: resuming with a client attached fails GSP firmware boot and
  # leaves the GPU needing a reset.
  #
  #   NVRM: gpuPowerManagementResume: GSP boot failed at resume: 0x62
  #   NVRM: Xid 154, GPU recovery action changed to 0x1 (GPU Reset Required)
  #   WARNING: nvidia/nv.c:4564 at nv_restore_user_channels
  #
  # Reproduced deliberately: suspending with the dGPU idle is clean, suspending
  # with Firefox running is not. Hiding the NVIDIA EGL, GLX and Vulkan drivers
  # from this process leaves it nothing to open. Rendering keeps working on the
  # iGPU, which is what the compositor already uses.
  #
  # These variables are set on the wrapper rather than in home.sessionVariables
  # because they are not Firefox-specific: session-wide they would also strip
  # the dGPU from games, breaking nvidia-offload.
  firefoxOnIgpu = pkgs.firefox.overrideAttrs (old: {
    makeWrapperArgs =
      (old.makeWrapperArgs or [])
      ++ [
        "--set"
        "MOZ_DRM_DEVICE"
        igpuRenderNode
        "--set"
        "__EGL_VENDOR_LIBRARY_FILENAMES"
        "${mesaEglVendor}"
        "--set"
        "__GLX_VENDOR_LIBRARY_NAME"
        "mesa"
        "--set"
        "VK_LOADER_DRIVERS_DISABLE"
        "nvidia_icd.json"
      ];
  });
in {
  stylix.targets.firefox.enable = false;

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
  };

  # Override desktop entry so launcher runs Firefox under native Wayland
  xdg.desktopEntries.firefox = {
    name = "Firefox Web Browser";
    exec = "firefox %U";
    icon = "firefox";
    type = "Application";
    categories = ["Network" "WebBrowser"];
    terminal = false;
    mimeType = [
      "text/html"
      "text/xml"
      "application/xhtml+xml"
      "application/vnd.mozilla.xul+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
    actions = {
      "new-window" = {
        name = "Open a New Window";
        exec = "firefox --new-window %U";
      };
      "new-private-window" = {
        name = "Open a New Private Window";
        exec = "firefox --private-window %U";
      };
    };
  };

  programs.firefox = {
    enable = true;
    package = lib.mkIf isHybrid firefoxOnIgpu;
    configPath = "${config.xdg.configHome}/mozilla/firefox";
    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;
      extensions.force = true;
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };
    };
    # Policies apply globally to all profiles and won't delete your history/extensions
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = false;
        Cryptomining = true;
        Fingerprinting = true;
      };
      DisablePocket = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      DontCheckDefaultBrowser = true;
      DisplayBookmarksToolbar = "never"; # or "always"
      DisplayMenuBar = "default-off";
      SearchBar = "unified";

      # Hardware Acceleration & Performance
      HardwareAcceleration = true;
      # Preferences allow setting any about:config value
      Preferences = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = {
          Value = true;
          Status = "locked";
        };
        "gfx.webrender.all" = {
          Value = true;
          Status = "locked";
        };
        "gfx.webrender.compositor" = {
          Value = false;
          Status = "locked";
        };
        "widget.wayland.opaque-region.enabled" = {
          Value = false;
          Status = "locked";
        };
        "media.ffmpeg.vaapi.enabled" = {
          Value = true;
          Status = "locked";
        };
        "media.rdd-ffmpeg.enabled" = {
          Value = true;
          Status = "locked";
        };
        "media.av1.enabled" = {
          Value = true;
          Status = "locked";
        };
        "browser.cache.disk.enable" = false;
        "browser.cache.memory.capacity" = 1048576;
        "browser.sessionstore.interval" = 600000;
        "privacy.donottrackheader.enabled" = true;
        "browser.tabs.firefox-view" = false;
        "browser.compactmode.show" = true;
        "browser.uidensity" = 1;
      };
    };
  };
}
