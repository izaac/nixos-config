{
  pkgs,
  userConfig,
  ...
}: {
  home = {
    packages = [pkgs.distrobox];

    # --- Distrobox: GC Survival ---
    # Link stable host-side paths so exported helpers survive profile updates and garbage collection.
    sessionVariables = {
      DBX_CONTAINER_ALWAYS_PULL = "1";
      # Force Distrobox to mount the stable symlink instead of the raw /nix/store path
      DBX_NON_INTERACTIVE = "1";
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
      SUDO_BIN="/home/${userConfig.username}/.local/share/distrobox/bin/sudo"
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

    # ONE-TIME bootstrap for the rhel10 container.
    # Why this exists: distrobox-init runs `dnf install` for base shell tools
    # immediately after creation. The rhel10 INI mounts the (empty) host
    # subscription dirs over /etc/rhsm and /etc/pki/entitlement, which shadows
    # UBI's bundled certs. With no certs, DNF falls onto subscribed RHEL repos
    # and fails — a chicken-and-egg the assemble flow can't break.
    #
    # The fix: register in a plain podman container (no volume shadowing),
    # copy the resulting certs into the host volume dirs, then let distrobox
    # assemble re-create rhel10 normally — now with populated volumes.
    #
    # Run once via `db-rhel-bootstrap`. After it succeeds, `db-up`/`db-rm`
    # cycles preserve the registration via the host volumes, and `db-rhel-init`
    # handles routine refresh + base package install.
    "distrobox/rhel10-bootstrap.sh".text = ''
      #!/bin/sh
      set -e

      HOST_DIR="$HOME/.local/share/distrobox/rhel10"
      IMAGE="registry.access.redhat.com/ubi10/ubi:latest"
      TMP_NAME="rhel10-bootstrap"

      # Detect whichever container runtime distrobox is using (docker on this
      # host today, podman on systems with virtualisation.podman.enable).
      RUNTIME="''${DBX_CONTAINER_MANAGER:-}"
      if [ -z "$RUNTIME" ]; then
        if command -v podman >/dev/null 2>&1; then
          RUNTIME=podman
        elif command -v docker >/dev/null 2>&1; then
          RUNTIME=docker
        else
          echo "!! No podman or docker on host." >&2
          exit 1
        fi
      fi
      echo ">> Using container runtime: $RUNTIME"

      echo ">> 1/6  Pulling $IMAGE"
      "$RUNTIME" pull "$IMAGE"

      echo ">> 2/6  Tearing down any previous bootstrap container"
      "$RUNTIME" rm -f "$TMP_NAME" >/dev/null 2>&1 || true

      echo ">> 3/6  Starting temporary bootstrap container (no volume shadowing)"
      "$RUNTIME" run -d --name "$TMP_NAME" "$IMAGE" sleep infinity >/dev/null

      echo ">> 4/6  Registering with Red Hat (interactive)"
      "$RUNTIME" exec -it "$TMP_NAME" subscription-manager register
      # RHEL 9.x+ defaults to Simple Content Access (SCA), which dropped
      # `subscription-manager attach`. Registration alone grants entitlements.
      # On older orgs that still require classic attach, opt-in with
      # ATTACH=1 db-rhel-bootstrap.
      if [ "''${ATTACH:-0}" = "1" ]; then
        "$RUNTIME" exec -it "$TMP_NAME" subscription-manager attach --auto
      fi
      "$RUNTIME" exec -it "$TMP_NAME" subscription-manager refresh

      echo ">> 5/6  Copying entitlement state to $HOST_DIR"
      mkdir -p "$HOST_DIR"/rhsm "$HOST_DIR"/pki-entitlement "$HOST_DIR"/pki-consumer "$HOST_DIR"/var-lib-rhsm
      "$RUNTIME" cp "$TMP_NAME":/etc/rhsm/.            "$HOST_DIR/rhsm/"
      "$RUNTIME" cp "$TMP_NAME":/etc/pki/entitlement/. "$HOST_DIR/pki-entitlement/"
      "$RUNTIME" cp "$TMP_NAME":/etc/pki/consumer/.    "$HOST_DIR/pki-consumer/"
      "$RUNTIME" cp "$TMP_NAME":/var/lib/rhsm/.        "$HOST_DIR/var-lib-rhsm/"
      "$RUNTIME" rm -f "$TMP_NAME" >/dev/null

      echo ">> 6/6  Re-creating rhel10 via distrobox assemble (volumes populated)"
      distrobox stop rhel10 -Y >/dev/null 2>&1 || true
      distrobox rm   rhel10 -Y >/dev/null 2>&1 || true
      distrobox assemble create --file "$HOME/.config/distrobox/distrobox.ini" --name rhel10

      echo ""
      echo ">> Bootstrap complete. Use 'db-rhel' to enter, or 'db-rhel-init' to install base packages."
    '';

    # Routine post-bootstrap setup for the rhel10 container.
    # Run via `db-rhel-init` after `db-rhel-bootstrap` has populated the host
    # volumes. Idempotent: refreshes the entitlement and installs base packages.
    "distrobox/rhel10-register.sh".text = ''
      #!/bin/sh
      set -e

      # Verify subscription is active (volumes carry it across rebuilds).
      if ! sudo subscription-manager status >/dev/null 2>&1; then
        echo "!! Not registered. Run 'db-rhel-bootstrap' first." >&2
        exit 1
      fi

      sudo subscription-manager refresh
      sudo dnf -y clean all
      sudo dnf -y makecache
      sudo dnf install -y git vim htop
    '';

    # Enable EPEL inside the rhel10 container.
    # Runs from init_hooks on every db-up. Idempotent: skips work that's
    # already done. Requires CodeReady Builder repo for EPEL build-time deps.
    "distrobox/rhel10-epel.sh".text = ''
      #!/bin/sh
      set -e

      # CodeReady Builder ships EPEL's build-time deps. Enable both the full
      # RHEL and UBI variants — whichever the active subscription exposes
      # will succeed; the other returns non-fatal "repo not found".
      for REPO in \
        codeready-builder-for-rhel-10-x86_64-rpms \
        codeready-builder-for-ubi-10-x86_64-rpms; do
        sudo subscription-manager repos --enable "$REPO" 2>&1 \
          | grep -v "matches no repositories" || true
      done

      if rpm -q epel-release >/dev/null 2>&1; then
        echo ">> epel-release already installed"
      else
        echo ">> installing epel-release"
        sudo dnf install -y \
          https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm
      fi
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
      init_hooks="sh /home/${userConfig.username}/.config/distrobox/sudo-fix.sh"
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
      init_hooks="sh /home/${userConfig.username}/.config/distrobox/sudo-fix.sh && sh /home/${userConfig.username}/.config/distrobox/nvidia-setup.sh"
      shell=/bin/bash

      [debi]
      image=debian:latest
      pull=true
      additional_packages="git curl wget neovim ripgrep lsd fastfetch"
      init=false
      nvidia=true
      init_hooks="sh /home/${userConfig.username}/.config/distrobox/sudo-fix.sh"
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
      init_hooks="sh /home/${userConfig.username}/.config/distrobox/sudo-fix.sh"

      # === RHEL 10 (UBI image + real Red Hat subscription) ===
      # Persists subscription state across db-rm/db-up via host volume mounts.
      # First-time bootstrap (volumes empty) MUST run `db-rhel-init` before
      # `db-rhel`: the helper registers with subscription-manager and installs
      # base packages. After that, certs live in the host volumes and every
      # subsequent rebuild picks them back up.
      # additional_packages is intentionally empty: dnf needs a working repo,
      # which needs subscription certs, which only exist after first register.
      [rhel10]
      image=registry.access.redhat.com/ubi10/ubi:latest
      pull=true
      init=false
      nvidia=true
      shell=/bin/bash
      volume="/home/${userConfig.username}/.local/share/distrobox/rhel10/rhsm:/etc/rhsm /home/${userConfig.username}/.local/share/distrobox/rhel10/pki-entitlement:/etc/pki/entitlement /home/${userConfig.username}/.local/share/distrobox/rhel10/pki-consumer:/etc/pki/consumer /home/${userConfig.username}/.local/share/distrobox/rhel10/var-lib-rhsm:/var/lib/rhsm"
      init_hooks="sh /home/${userConfig.username}/.config/distrobox/sudo-fix.sh && sh /home/${userConfig.username}/.config/distrobox/rhel10-epel.sh"
    '';
  };

  # Ensure host directories exist for shared Distrobox state.
  # The rhel10/* dirs hold subscription state populated by db-rhel-bootstrap.
  # Ownership left unset (`-`) so systemd-tmpfiles won't re-chown live certs:
  # after bootstrap the dirs are owned by Chief; the rhel10 distrobox runs
  # rootful via docker (no userns remap), so root inside the container can
  # still read them.
  systemd.user.tmpfiles.rules = [
    "d %h/.local/share/distrobox/bin 0755 - - - -"

    "d %h/.local/share/distrobox/rhel10/rhsm 0755 - - - -"
    "d %h/.local/share/distrobox/rhel10/pki-entitlement 0755 - - - -"
    "d %h/.local/share/distrobox/rhel10/pki-consumer 0755 - - - -"
    "d %h/.local/share/distrobox/rhel10/var-lib-rhsm 0750 - - - -"
  ];

  # Alias to easily create/update these containers
  programs.bash.shellAliases = {
    db-up = "distrobox assemble create --file /home/${userConfig.username}/.config/distrobox/distrobox.ini";
    db-rm = "distrobox assemble rm --file /home/${userConfig.username}/.config/distrobox/distrobox.ini";
    db-arch = "distrobox enter archy";
    db-ubu = "distrobox enter ubu";
    db-debian = "distrobox enter debi";
    db-rhel = "distrobox enter rhel10";
    db-rhel-bootstrap = "bash /home/${userConfig.username}/.config/distrobox/rhel10-bootstrap.sh";
    db-rhel-init = "distrobox enter rhel10 -- bash /home/${userConfig.username}/.config/distrobox/rhel10-register.sh";
    db-alpine = "distrobox enter alpy";
  };
}
