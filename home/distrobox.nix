{
  config,
  pkgs,
  ...
}: {
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

  # Script to automate NVIDIA driver linking in Ubuntu containers
  xdg.configFile = {
    # Sudo wrapper for rootless containers — runs commands as root via podman exec.
    # Placed in distrobox/bin which is first in PATH, ahead of host sudo.
    "distrobox/sudo-fix.sh".text = ''
      #!/bin/sh
      SUDO_BIN="${config.home.homeDirectory}/.local/share/distrobox/bin/sudo"
      mkdir -p "$(dirname "$SUDO_BIN")"
      cat > "$SUDO_BIN" <<'WRAPPER'
      #!/bin/sh
      # Use whichever container runtime distrobox picked (podman or docker).
      RUNTIME="''${DBX_CONTAINER_MANAGER:-}"
      if [ -z "$RUNTIME" ]; then
        if command -v podman >/dev/null 2>&1; then
          RUNTIME=podman
        elif command -v docker >/dev/null 2>&1; then
          RUNTIME=docker
        else
          echo "sudo-fix: no podman or docker on host" >&2
          exit 1
        fi
      fi
      exec distrobox-host-exec "$RUNTIME" exec -it -u root "$CONTAINER_ID" "$@"
      WRAPPER
      chmod +x "$SUDO_BIN"
    '';

    "distrobox/nvidia-setup.sh".text = ''
      #!/bin/sh
      # 1. Enable 32-bit architecture and multiverse repos
      sudo dpkg --add-architecture i386
      sudo sed -i 's/Components: main restricted/Components: main restricted universe multiverse/g' /etc/apt/sources.list.d/ubuntu.sources
      sudo apt update

      # 2. Link Host NVIDIA Drivers (Vulkan/OpenGL)
      sudo mkdir -p /usr/share/vulkan/icd.d
      printf '{"file_format_version" : "1.0.0","ICD": {"library_path": "/run/host/run/opengl-driver/lib/libGLX_nvidia.so.0","api_version" : "1.3.260"}}' | sudo tee /usr/share/vulkan/icd.d/nvidia_icd.json > /dev/null

      # 3. Configure Linker
      echo '/run/host/run/opengl-driver/lib' | sudo tee /etc/ld.so.conf.d/nvidia.conf > /dev/null
      echo '/run/host/run/opengl-driver-32/lib' | sudo tee -a /etc/ld.so.conf.d/nvidia.conf > /dev/null
      sudo ldconfig
    '';

    # Declarative Distrobox Configuration
    # Run 'distrobox assemble create --file ~/.config/distrobox/distrobox.ini' to build these.
    "distrobox/distrobox.ini".text = ''
      [archy]
      image=archlinux:latest
      pull=true
      additional_packages="git vim neovim ripgrep lsd fastfetch nss alsa-lib atk cups libdrm libxcomposite libxdamage libxext libxfixes libxkbcommon libxrandr mesa pango cairo gtk3"
      init=false
      nvidia=true
      init_hooks="sh ${config.home.homeDirectory}/.config/distrobox/sudo-fix.sh"
      shell=/bin/bash
      # === Ubuntu Gaming Container (The "Golden Recipe" for NixOS + NVIDIA) ===
      # This container uses ~/.config/distrobox/nvidia-setup.sh to automatically
      # link host NVIDIA drivers and configure 32-bit support for Steam.
      [ubu]
      image=ubuntu:24.04
      pull=true
      additional_packages="neovim git curl wget vim mesa-utils libvulkan1 libgl1-mesa-dri libglx-mesa0 libegl-mesa0 pulseaudio-utils x11-utils vulkan-tools libnvidia-egl-wayland1"
      init=false
      nvidia=true
      init_hooks="sh ${config.home.homeDirectory}/.config/distrobox/sudo-fix.sh && sh ${config.home.homeDirectory}/.config/distrobox/nvidia-setup.sh"
      shell=/bin/bash

      [debi]
      image=debian:latest
      pull=true
      additional_packages="git curl wget neovim ripgrep lsd fastfetch"
      init=false
      nvidia=true
      init_hooks="sh ${config.home.homeDirectory}/.config/distrobox/sudo-fix.sh"
      shell=/bin/bash

      # === Alpine OpenRC Sandbox ===
      # For testing OpenRC service management (rc-service, rc-update, openrc-run scripts).
      # NVIDIA disabled: musl libc binaries don't pair with glibc host driver.
      # OpenRC won't run as PID 1 in distrobox — start it manually with `openrc default`.
      [alpy]
      image=alpine:latest
      pull=true
      additional_packages="openrc openrc-init bash shadow util-linux git vim curl wget fastfetch eudev"
      init=false
      nvidia=false
      shell=/bin/bash
      init_hooks="sh ${config.home.homeDirectory}/.config/distrobox/sudo-fix.sh"
    '';
  };

  # Ensure host directories exist for shared Distrobox state.
  systemd.user.tmpfiles.rules = [
    "d %h/.local/share/distrobox/bin 0755 - - - -"
  ];

  # Rootless Podman API socket (Docker-compatible) for docker-compose /
  # lazydocker. Socket-activated: connecting starts the user service on demand.
  systemd.user.sockets.podman = {
    Unit.Description = "Podman API socket (rootless, docker-compatible)";
    Socket = {
      ListenStream = "%t/podman/podman.sock";
      SocketMode = "0660";
    };
    Install.WantedBy = ["sockets.target"];
  };

  systemd.user.services.podman = {
    Unit = {
      Description = "Podman API service (rootless)";
      Requires = ["podman.socket"];
      After = ["podman.socket"];
      Documentation = ["man:podman-system-service(1)"];
    };
    Service = {
      Type = "exec";
      KillMode = "process";
      ExecStart = "${pkgs.podman}/bin/podman system service --time=0";
    };
    Install.Also = ["podman.socket"];
  };

  # Alias to easily create/update these containers
  home.shellAliases = {
    db-up = "distrobox assemble create --file ${config.home.homeDirectory}/.config/distrobox/distrobox.ini";
    db-rm = "distrobox assemble rm --file ${config.home.homeDirectory}/.config/distrobox/distrobox.ini";
    db-arch = "distrobox enter archy -- zsh";
    db-ubu = "distrobox enter ubu -- bash";
    db-debian = "distrobox enter debi -- bash";
    db-alpine = "distrobox enter alpy -- sh";
  };
}
