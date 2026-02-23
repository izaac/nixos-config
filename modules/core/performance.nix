{ pkgs, ... }:

{
  # --- MEMORY MANAGEMENT (ZRAM) ---
  # Highly recommended for NVMe & high-core systems to prevent disk-thrashing
  zramSwap = {
    enable = true;
    algorithm = "zstd"; # Best balance of speed and compression
    memoryPercent = 100; # Use up to 100% of RAM as compressed swap (as previously configured)
    priority = 100; # High priority to ensure it's used before disk swap
  };

  # --- KERNEL TUNING ---
  boot.kernel.sysctl = {
    # ZRAM Swappiness (Aggressive swap-to-zram, avoids disk wait)
    "vm.swappiness" = 180;
    "vm.vfs_cache_pressure" = 50; # Keep filesystem cache longer (snappier Nautilus)
    "vm.dirty_ratio" = 10;
    "vm.dirty_background_ratio" = 5;

    # Networking performance (lower latency)
    "net.core.default_qdisc" = "fq"; # Fair Queueing (Bufferbloat reduction)
    "net.ipv4.tcp_congestion_control" = "bbr"; # Google BBR congestion control
  };

  # --- GAMING & INPUT LATENCY ---
  boot.kernelParams = [
    # Transparent Hugepages (THP) - 'madvise' allows apps (like Steam/Proton) 
    # to opt-in, reducing TLB misses without the overhead of 'always'.
    "transparent_hugepage=madvise"
    
    # Disable USB autosuspend to eliminate tiny wake-up delays for mice/keyboards.
    "usbcore.autosuspend=-1"
  ];

  # dbus-broker (Fedora/GNOME standard)
  # High-performance D-Bus message broker that reduces latency in desktop communication.
  services.dbus.implementation = "broker";

  # Security Hardening
  security.apparmor = {
    enable = true;
    includes = let
      tunables = "${pkgs.apparmor-profiles}/etc/apparmor.d/tunables";
    in {
      "tunables/global" = builtins.readFile "${tunables}/global";
      "tunables/home" = builtins.readFile "${tunables}/home";
      "tunables/multiarch" = builtins.readFile "${tunables}/multiarch";
      "tunables/proc" = builtins.readFile "${tunables}/proc";
      "tunables/alias" = builtins.readFile "${tunables}/alias";
      "tunables/kernelvars" = builtins.readFile "${tunables}/kernelvars";
      "tunables/system" = builtins.readFile "${tunables}/system";
      "tunables/xdg-user-dirs" = builtins.readFile "${tunables}/xdg-user-dirs";
      "tunables/share" = builtins.readFile "${tunables}/share";
      "tunables/etc" = builtins.readFile "${tunables}/etc";
      "tunables/run" = builtins.readFile "${tunables}/run";
    };
    policies = {
      "bin.chromium".profile = builtins.replaceStrings
        [ "profile chromium /usr/lib/@{chromium}/@{chromium} flags=(unconfined) {" ]
        [ 
          ''
          profile chromium /nix/store/*/libexec/chromium/chromium {
            # Default allow all (Blacklist mode)
            file,
            network,
            dbus,
            signal,
            ptrace,
            unix,
            mount,
            remount,
            umount,
            pivot_root,

            # Deny sensitive data
            audit deny @{HOME}/.ssh/ r,
            audit deny @{HOME}/.ssh/** rwklx,
            audit deny @{HOME}/.gnupg/ r,
            audit deny @{HOME}/.gnupg/** rwklx,
            audit deny @{HOME}/.aws/ r,
            audit deny @{HOME}/.aws/** rwklx,
            audit deny @{HOME}/.kube/ r,
            audit deny @{HOME}/.kube/** rwklx,
          ''
        ]
        (builtins.readFile "${pkgs.apparmor-profiles}/etc/apparmor.d/chromium");
      "firefox".profile = builtins.replaceStrings
        [ "profile firefox /{usr/lib/firefox{,-esr,-beta,-devedition,-nightly},opt/firefox}/firefox{,-esr,-bin} flags=(unconfined) {" ]
        [ 
          ''
          profile firefox /nix/store/*/lib/firefox/firefox {
            # Default allow all (Blacklist mode)
            file,
            network,
            dbus,
            signal,
            ptrace,
            unix,
            mount,
            remount,
            umount,
            pivot_root,

            # Deny sensitive data
            audit deny @{HOME}/.ssh/ r,
            audit deny @{HOME}/.ssh/** rwklx,
            audit deny @{HOME}/.gnupg/ r,
            audit deny @{HOME}/.gnupg/** rwklx,
            audit deny @{HOME}/.aws/ r,
            audit deny @{HOME}/.aws/** rwklx,
            audit deny @{HOME}/.kube/ r,
            audit deny @{HOME}/.kube/** rwklx,
          ''
        ]
        (builtins.readFile "${pkgs.apparmor-profiles}/etc/apparmor.d/firefox");
    };
  };

  environment.systemPackages = [ pkgs.apparmor-utils ];

  # Ananicy-cpp (Auto-nice daemon) - Disabled per Anticipation Strategy
  services.ananicy.enable = false;

  # Irqbalance - Disabled per Anticipation Strategy
  services.irqbalance.enable = false;
}
