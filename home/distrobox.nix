{
  config,
  pkgs,
  lib,
  osConfig ? {},
  ...
}:
# distrobox drives rootless Podman, so this whole module is dead weight on a
# host that does not run Podman: the user socket would point at nothing and the
# `docker` shim in DOCKER_HOST would dangle. Follow the system-level switch
# (mySystem.core.virtualization) rather than naming hosts here.
lib.mkIf (osConfig.virtualisation.podman.enable or false) (let
  initHooks = "sh ${config.home.homeDirectory}/.config/distrobox/sudo-fix.sh && sh ${config.home.homeDirectory}/.config/distrobox/tz-sync.sh && sh ${config.home.homeDirectory}/.config/distrobox/xdg-open-bridge.sh && sh ${config.home.homeDirectory}/.config/distrobox/cli-tools-setup.sh";
in {
  home = {
    packages = [pkgs.distrobox];

    # --- Distrobox: GC Survival ---
    # Link stable host-side paths so exported helpers survive profile updates and garbage collection.
    sessionVariables = {
      # Don't pull the image on every `distrobox enter` — saves seconds +
      # bandwidth per shell. Use `db-up` (distrobox assemble) for explicit
      # refreshes when an image needs updating.
      DBX_CONTAINER_ALWAYS_PULL = "0";
      DBX_NON_INTERACTIVE = "1";
      # Pin the runtime to Podman (distrobox's reference manager) so the
      # docker-compat shim is never auto-selected.
      DBX_CONTAINER_MANAGER = "podman";
      # Point the `docker` CLI / docker-compose / lazydocker at the rootless
      # Podman user socket (enabled below) instead of a rootful system socket.
      DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
    };

    # Host-visible wrappers belong in ~/.local/bin.
    file = {
      ".local/bin/distrobox-init" = {
        source = "${pkgs.distrobox}/bin/distrobox-init";
        executable = true;
      };
      ".local/bin/distrobox-export" = {
        source = "${pkgs.distrobox}/bin/distrobox-export";
        executable = true;
      };
      ".local/bin/distrobox-host-exec" = {
        source = "${pkgs.distrobox}/bin/distrobox-host-exec";
        executable = true;
      };
    };
  };

  # Container init-hook helper scripts and the declarative distrobox.ini.
  xdg.configFile = {
    "distrobox/sudo-fix.sh" = {
      source = ./distrobox/sudo-fix.sh;
      executable = true;
    };
    "distrobox/tz-sync.sh" = {
      source = ./distrobox/tz-sync.sh;
      executable = true;
    };
    "distrobox/xdg-open-bridge.sh" = {
      source = ./distrobox/xdg-open-bridge.sh;
      executable = true;
    };
    "distrobox/cli-tools-setup.sh" = {
      source = ./distrobox/cli-tools-setup.sh;
      executable = true;
    };

    # Declarative Distrobox Configuration
    # Run 'distrobox assemble create --file ~/.config/distrobox/distrobox.ini' to build these.
    "distrobox/distrobox.ini".text = ''
      [archy]
      image=archlinux:latest
      pull=true
      additional_packages="git vim neovim ripgrep lsd fastfetch wl-clipboard fzf zoxide eza bat fd jq direnv starship btop nss alsa-lib atk cups libdrm libxcomposite libxdamage libxext libxfixes libxkbcommon libxrandr mesa pango cairo gtk3"
      init=false
      init_hooks="${initHooks}"
      shell=/bin/bash

      # === Ubuntu Gaming Container (Steam / Proton sandbox) ===
      # Mesa + Vulkan come from the host GL stack through distrobox; no
      # driver-linking hook needed on Intel Arc (in-tree xe driver + iHD).
      [ubu]
      image=ubuntu:24.04
      pull=true
      additional_packages="neovim git curl wget vim zsh wl-clipboard fzf zoxide eza bat ripgrep fd-find jq direnv btop mesa-utils libvulkan1 libgl1-mesa-dri libglx-mesa0 libegl-mesa0 pulseaudio-utils x11-utils vulkan-tools"
      init=false
      init_hooks="${initHooks}"
      shell=/bin/bash

      [debi]
      image=debian:latest
      pull=true
      additional_packages="git curl wget neovim zsh ripgrep lsd fastfetch wl-clipboard fzf zoxide eza bat fd-find jq direnv starship btop"
      init=false
      init_hooks="${initHooks}"
      shell=/bin/bash

      # === Alpine OpenRC Sandbox ===
      # For testing OpenRC service management (rc-service, rc-update, openrc-run scripts).
      # NVIDIA disabled: musl libc binaries don't pair with glibc host driver.
      # OpenRC won't run as PID 1 in distrobox — start it manually with `openrc default`.
      [alpy]
      image=alpine:latest
      pull=true
      additional_packages="openrc openrc-init bash shadow util-linux git vim curl wget fastfetch eudev fzf zoxide ripgrep fd bat jq"
      init=false
      nvidia=false
      shell=/bin/bash
      init_hooks="${initHooks}"

      # === openSUSE Leap 16.1 ===
      [suse]
      image=registry.opensuse.org/opensuse/leap:16.1
      pull=true
      # neovim is installed from the official release tarball into /usr/local
      # (see pre_init_hooks) to avoid clashing with the slower zypper package.
      additional_packages="git curl wget zsh ripgrep fastfetch terminfo wl-clipboard libpulse0 pulseaudio-utils alsa-plugins-pulse fzf zoxide eza bat fd jq direnv starship btop"
      init=false
      shell=/bin/bash
      pre_init_hooks="zypper ref && zypper -n install -y bash-completion bc bzip2 curl diffutils findutils glibc-locale glibc-locale-base gnupg hostname iputils keyutils less lsof shadow tar terminfo wl-clipboard fzf zoxide eza bat fd jq direnv starship btop || true; test -f /usr/local/bin/nvim || (curl -fsSL https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz | tar -xz -C /usr/local --strip-components=1) || true"
      init_hooks="${initHooks}"

      # === Slackware Distrobox ===
      # Clean CLI base with pulseaudio, slackpkg, and full host integration
      [slack]
      image=ghcr.io/izaac/slackware-distrobox:latest
      pull=true
      init=false
      shell=/bin/bash
      init_hooks="${initHooks}"
    '';
  };

  # Host directories & systemd user services for Podman/Distrobox
  systemd.user = {
    tmpfiles.rules = [
      "d %h/.local/share/distrobox/bin 0755 - - - -"
    ];

    # Rootless Podman API socket (Docker-compatible) for docker-compose /
    # oxker. Socket-activated: connecting starts the user service on demand.
    sockets.podman = {
      Unit.Description = "Podman API socket (rootless, docker-compatible)";
      Socket = {
        ListenStream = "%t/podman/podman.sock";
        SocketMode = "0660";
      };
      Install.WantedBy = ["sockets.target"];
    };

    services.podman = {
      Unit = {
        Description = "Podman API service (rootless)";
        Requires = ["podman.socket"];
        After = ["podman.socket"];
        Documentation = ["man:podman-system-service(1)"];
      };
      Service = {
        Type = "exec";
        KillMode = "process";
        Environment = [
          "PATH=/run/wrappers/bin:/run/current-system/sw/bin"
        ];
        ExecStart = "${pkgs.podman}/bin/podman system service --time=0";
      };
      Install.Also = ["podman.socket"];
    };
  };

  # Alias to easily create/update these containers
  home.shellAliases = {
    db-up = "distrobox assemble create --file ${config.home.homeDirectory}/.config/distrobox/distrobox.ini";
    db-rm = "distrobox assemble rm --file ${config.home.homeDirectory}/.config/distrobox/distrobox.ini";
    db-arch = "distrobox enter archy -- zsh";
    db-ubu = "distrobox enter ubu -- zsh";
    db-debian = "distrobox enter debi -- zsh";
    db-alpine = "distrobox enter alpy -- sh";
    db-suse = "distrobox enter suse -- zsh";
    db-slack = "distrobox enter slack -- zsh";
  };
})
