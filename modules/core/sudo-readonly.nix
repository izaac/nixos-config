{
  config,
  lib,
  pkgs,
  userConfig,
  ...
}: let
  cfg = config.mySystem.core."sudo-readonly";

  bin = "/run/current-system/sw/bin";

  # Genuinely inert diagnostics: no shell escape, no state mutation, no
  # interactive pager. These are safe to expose passwordless.
  #
  # Deliberately EXCLUDED (each grants passwordless root or destroys state):
  #   nix / nix-store ...... `sudo nix run nixpkgs#bash` -> root shell
  #   systemctl ............ pager escape (status -> less -> !sh) + start/stop
  #   journalctl ........... pager escape (wrapped read-only below instead)
  #   ip ................... `ip netns exec <ns> sh` -> root shell
  #   nft (raw) ............ `nft -f` rewrites firewall (wrapped list below)
  #   cryptsetup / nvme .... luksFormat / format destroy disks (use smartctl)
  #   bootctl / udevadm .... tamper with boot / trigger device actions
  #   dmesg ................ kernel.dmesg_restrict=0 already allows non-root
  readonlyCommands = [
    # Hardware introspection
    "${bin}/lspci"
    "${bin}/lsusb"
    "${bin}/lshw"
    "${bin}/lsblk"
    "${bin}/lsof"
    "${bin}/blkid"
    "${bin}/smartctl"
    "${bin}/dmidecode"

    # Network socket state (read-only view)
    "${bin}/ss"

    # Nix introspection (read-only)
    "${bin}/nixos-option"

    # I/O profiling
    "${bin}/iotop"
  ];

  # Tools that AI agents genuinely need at root but which expose a root
  # shell (pager escape) or mutate state when called raw. We ship locked
  # wrappers that hard-force read-only behaviour, then NOPASSWD only the
  # wrapper's exact store path.
  journalRead = pkgs.writeShellApplication {
    name = "journal-read";
    runtimeInputs = [pkgs.systemd];
    # --no-pager removes the LESS shell-escape; journalctl itself cannot
    # spawn a shell or change system state once the pager is disabled.
    text = ''exec journalctl --no-pager "$@"'';
  };

  nftShow = pkgs.writeShellApplication {
    name = "nft-show";
    runtimeInputs = [pkgs.nftables];
    # Fixes the verb to `list`, so the ruleset can be inspected but never
    # loaded/flushed (`nft -f` / `nft flush` are unreachable).
    text = ''exec nft list "$@"'';
  };

  wrappedCommands = [
    "${journalRead}/bin/journal-read"
    "${nftShow}/bin/nft-show"
  ];
in {
  options.mySystem.core."sudo-readonly" = {
    enable = lib.mkEnableOption "NOPASSWD sudo for read-only system diagnostics";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [journalRead nftShow];

    security.sudo-rs.extraRules = [
      {
        users = [userConfig.username];
        commands =
          map (command: {
            inherit command;
            # No SETENV: it would let the caller inject env (e.g. LD_PRELOAD)
            # into the privileged command. Plain NOPASSWD only.
            options = ["NOPASSWD"];
          })
          (readonlyCommands ++ wrappedCommands);
      }
    ];
  };
}
