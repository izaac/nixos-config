{
  lib,
  pkgs,
  osConfig ? {},
  ...
}: let
  vfio = osConfig.mySystem.core.vfio or {};
  enabled = (vfio.enable or false) && (vfio.lookingGlass.enable or false);

  vm = "win11";
  # kvmfr exposes the guest framebuffer as a device, which removes one copy
  # compared with both sides going through a /dev/shm file. Falls back to the
  # shm path when the module is not loaded.
  useKvmfr = vfio.lookingGlass.kvmfr or false;
  shm =
    if useKvmfr
    then "/dev/kvmfr0"
    else "/dev/shm/looking-glass";

  # virt-manager's built-in viewer only speaks SPICE, and the guest has no
  # emulated adapter left, so it would show a blank window. Looking Glass reads
  # the real framebuffer out of shared memory instead, so this wrapper starts
  # the guest if needed and waits for the host application inside it to publish
  # a frame before connecting.
  #
  # Hold ScrollLock for the on-screen menu; ScrollLock alone toggles capture.
  windowsVm = pkgs.writeShellApplication {
    name = "windows-vm";
    runtimeInputs = with pkgs; [libvirt looking-glass-client coreutils libnotify python3];
    text = ''
            set -euo pipefail
            export LIBVIRT_DEFAULT_URI=qemu:///system

            if ! virsh domstate ${vm} 2>/dev/null | grep -q running; then
              echo "starting ${vm}..."
              virsh start ${vm}
            fi

            # The guest publishes an LGMP header once its Looking Glass service is up.
            # Windows takes a while to get there from cold, so wait rather than
            # failing with an unhelpful error.
            #
            # kvmfr is a character device that only supports mmap, so read() fails
            # with EINVAL and the header has to be mapped instead.
            for _ in $(seq 1 60); do
              if [ -r "${shm}" ] && python3 -c '
      import mmap, sys

      with open(sys.argv[1], "rb") as fh:
          with mmap.mmap(fh.fileno(), 4096, prot=mmap.PROT_READ) as mm:
              sys.exit(0 if mm[:4] == b"LGMP" else 1)
      ' "${shm}"; then
                # jitRender draws only when a new frame arrives rather than on a
                # timer, which removes a few milliseconds of latency.
                exec looking-glass-client -f "${shm}" win:jitRender=yes "$@"
              fi
              sleep 1
            done

            notify-send -u critical "Looking Glass" \
              "No frames on ${shm}. Is the Looking Glass host service running in the guest?"
            exit 1
    '';
  };
in {
  config = lib.mkIf enabled {
    home.packages = [windowsVm];

    xdg.desktopEntries.windows-vm = {
      name = "Windows VM";
      genericName = "Virtual Machine";
      comment = "Start the Windows guest and attach Looking Glass";
      exec = "${lib.getExe windowsVm} -F";
      icon = "virt-manager";
      terminal = false;
      categories = ["System" "Emulator"];
    };
  };
}
