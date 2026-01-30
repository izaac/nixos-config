{ pkgs, userConfig, ... }:

{
  home.packages = [ pkgs.distrobox ];

  # Declarative Distrobox Configuration
  # Run 'distrobox assemble create --file ~/.config/distrobox/distrobox.ini' to build these.
  xdg.configFile."distrobox/distrobox.ini".text = ''
    [archy]
    image=archlinux:latest
    pull=true
    additional_packages="git vim neovim ripgrep lsd fastfetch nss alsa-lib atk cups libdrm libxcomposite libxdamage libxext libxfixes libxkbcommon libxrandr mesa pango cairo gtk3"
    init=false
    nvidia=true
    # Export apps to host automatically
    # export="google-chrome"
    # === Ubuntu Gaming Container (The "Golden Recipe" for NixOS + NVIDIA) ===
    # If you recreate this container, run these steps inside 'ubu' to fix NVIDIA drivers:
    # 1. Link Host Driver:
    #    mkdir -p /usr/share/vulkan/icd.d
    #    echo '{"file_format_version" : "1.0.0", "ICD": { "library_path": "/run/host/run/opengl-driver/lib/libGLX_nvidia.so.0", "api_version" : "1.3.260" }}' > /usr/share/vulkan/icd.d/nvidia_icd.json
    # 2. Configure Linker:
    #    echo "/run/host/run/opengl-driver/lib" > /etc/ld.so.conf.d/nvidia.conf
    #    echo "/run/host/run/opengl-driver-32/lib" >> /etc/ld.so.conf.d/nvidia.conf
    #    ldconfig
    # 3. Install Steam (Valve .deb):
    #    dpkg --add-architecture i386
    #    sed -i 's/Components: main restricted/Components: main restricted universe multiverse/g' /etc/apt/sources.list.d/ubuntu.sources
    #    apt update
    #    wget https://repo.steampowered.com/steam/archive/stable/steam_latest.deb && apt install ./steam_latest.deb
    #
    # Future Automation (init_hooks):
    # init_hooks="dpkg --add-architecture i386 && sed -i 's/Components: main restricted/Components: main restricted universe multiverse/g' /etc/apt/sources.list.d/ubuntu.sources && apt update && mkdir -p /usr/share/vulkan/icd.d && echo '{\"file_format_version\" : \"1.0.0\",\"ICD\": {\"library_path\": \"/run/host/run/opengl-driver/lib/libGLX_nvidia.so.0\",\"api_version\" : \"1.3.260\"}}' > /usr/share/vulkan/icd.d/nvidia_icd.json && echo '/run/host/run/opengl-driver/lib' > /etc/ld.so.conf.d/nvidia.conf && echo '/run/host/run/opengl-driver-32/lib' >> /etc/ld.so.conf.d/nvidia.conf && ldconfig"
    [ubu]
    image=ubuntu:24.04
    pull=true
    additional_packages="build-essential neovim git curl wget vim mesa-utils libvulkan1 libgl1-mesa-dri libglx-mesa0 libegl-mesa0 pulseaudio-utils x11-utils"
    init=false
    nvidia=true

    [debi]
    pull=true
    additional_packages="build-essential git curl wget neovim ripgrep lsd fastfetch"
    init=false
    nvidia=true

    [rhel10]
    image=registry.access.redhat.com/ubi10/ubi:latest
    pull=true
    additional_packages="subscription-manager git vim"
    init=false
    nvidia=true
  '';

  # Alias to easily create/update these containers
  programs.bash.shellAliases = {
    db-up = "distrobox assemble create --file ~/.config/distrobox/distrobox.ini";
    db-rm = "distrobox assemble rm --file ~/.config/distrobox/distrobox.ini";
    db-arch = "distrobox enter archy";
    db-ubu = "distrobox enter ubu";
    db-debian = "distrobox enter debi";
    db-rhel = "distrobox enter rhel10";
  };
}