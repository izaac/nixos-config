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
      shell=/bin/bash
      # Export apps to host automatically
      # export="google-chrome"
      # === Ubuntu Gaming Container (The "Golden Recipe" for NixOS + NVIDIA) ===
      # This container uses ~/.config/distrobox/nvidia-setup.sh to automatically
      # link host NVIDIA drivers and configure 32-bit support for Steam.
      [ubu]
      image=ubuntu:24.04
      pull=true
      additional_packages="build-essential neovim git curl wget vim mesa-utils libvulkan1 libgl1-mesa-dri libglx-mesa0 libegl-mesa0 pulseaudio-utils x11-utils vulkan-tools libnvidia-egl-wayland1"
      init=false
      nvidia=true
      init_hooks="sh ~/.config/distrobox/nvidia-setup.sh"
      shell=/bin/bash

      [debi]
      image=debian:latest
      pull=true
      additional_packages="build-essential git curl wget neovim ripgrep lsd fastfetch"
      init=false
      nvidia=true
      shell=/bin/bash

      [rhel10]
      image=registry.access.redhat.com/ubi10/ubi:latest
      pull=true
      additional_packages="subscription-manager git vim"
      init=false
      nvidia=true
      shell=/bin/bash
      volume="/home/${userConfig.username}/.local/share/distrobox/rhel10/rhsm:/etc/rhsm /home/${userConfig.username}/.local/share/distrobox/rhel10/pki-entitlement:/etc/pki/entitlement /home/${userConfig.username}/.local/share/distrobox/rhel10/pki-consumer:/etc/pki/consumer /home/${userConfig.username}/.local/share/distrobox/rhel10/var-lib-rhsm:/var/lib/rhsm"
      init_hooks="if [ ! -f /etc/rhsm/ca/redhat-uep.pem ]; then dnf reinstall -y subscription-manager-rhsm-certificates subscription-manager; fi"
    '';
  };

  # Ensure host directories exist for shared Distrobox state.
  systemd.user.tmpfiles.rules = [
    "d %h/.local/share/distrobox/bin 0755 - - - -"

    # Persistent RHEL subscription volumes use UID/GID 100000, which maps to the container's root user.
    "d %h/.local/share/distrobox/rhel10/rhsm 0755 100000 100000 - -"
    "d %h/.local/share/distrobox/rhel10/pki-entitlement 0755 100000 100000 - -"
    "d %h/.local/share/distrobox/rhel10/pki-consumer 0755 100000 100000 - -"
    "d %h/.local/share/distrobox/rhel10/var-lib-rhsm 0750 100000 100000 - -"
  ];

  # Alias to easily create/update these containers
  programs.bash.shellAliases = {
    db-up = "distrobox assemble create --file /home/${userConfig.username}/.config/distrobox/distrobox.ini";
    db-rm = "distrobox assemble rm --file /home/${userConfig.username}/.config/distrobox/distrobox.ini";
    db-arch = "distrobox enter archy";
    db-ubu = "distrobox enter ubu";
    db-debian = "distrobox enter debi";
    db-rhel = "distrobox enter rhel10";
  };

  # --- Distrobox: bash-preexec array fix ---
  # Bash 5.1+ uses PROMPT_COMMAND arrays, which older bash-preexec fails to clean up.
  # This uses mkAfter to run AFTER atuin sources bash-preexec.sh, manually
  # triggering the install and scrubbing the broken strings so Atuin works.
  programs.bash.initExtra = pkgs.lib.mkAfter ''
    if [ -d "/run/host/nix/store" ] && type __bp_install &>/dev/null; then
      __bp_install
      if declare -p PROMPT_COMMAND 2>/dev/null | grep -q 'declare -a'; then
        for i in "''${!PROMPT_COMMAND[@]}"; do
          PROMPT_COMMAND[$i]="''${PROMPT_COMMAND[$i]//__bp_trap_string=\"\$(trap -p DEBUG)\"/}"
          PROMPT_COMMAND[$i]="''${PROMPT_COMMAND[$i]//trap - DEBUG/}"
          PROMPT_COMMAND[$i]="''${PROMPT_COMMAND[$i]//__bp_install/}"
        done
      fi
    fi
  '';
}
