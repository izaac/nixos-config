# GPU passthrough for the Windows 11 guest.
#
# Passthrough is the default configuration, because that is what this machine is
# mostly used for now. The RTX 5060 Ti cannot serve the host and a guest at the
# same time, so native Linux gaming lives in a `gaming` specialisation instead.
#
# Default entry: RTX 5060 Ti bound to vfio-pci and handed to the guest, host
#                desktop on the secondary RX 550.
# gaming entry:  host drives the RTX 5060 Ti through the NVIDIA driver.
#
# Limine numbers its menu entries including submenus, so the generated
# `default_entry: 3` always lands on the newest generation's "Default" leaf.
# Making passthrough the top-level configuration is therefore the only way to
# have it selected by default without fighting the bootloader, and it has the
# side benefit that `nh os switch` now does the right thing in the common case.
#
# IOMMU group 12 holds only 01:00.0 and 01:00.1, and the card advertises FLR, so
# no ACS override or reset workaround is required.
#
# The board's integrated GPU is disabled in BIOS and is not usable as a host GPU:
# it wedged the entire machine while compositing a plain desktop, with no guest
# involved and nothing in the journal. The RX 550 replaced it.
{lib, ...}: {
  # libvirt is available in both entries so the guest can be prepared and its
  # disk imported from either one.
  mySystem.core.libvirt = {
    enable = true;
    # Looking Glass reads frames from the kvmfr device, which the guest cannot
    # open unless libvirt's cgroup allow-list includes it.
    extraDeviceACL = ["/dev/kvmfr0"];
    # The guest preallocates its 16 GiB from a 1 GiB hugetlb reservation, so the
    # whole guest is covered by 16 page table entries and never depends on the
    # host having contiguous memory to spare at start time.
    guestHugepagesGB = 16;
    # Deliberately off: compacting memory for transparent huge pages is pointless
    # when the guest's pages are reserved at boot. Re-enable it if a guest is
    # ever added that does not take a hugetlb reservation.
    defragBeforeStart = false;
    # /mnt/data is a separate unencrypted disk. The home directory is on the
    # LUKS root and deliberately stays out of reach of the guest.
    #
    # SMB is off: the guest mounts this over virtiofs, which needs no account,
    # is not bound by QEMU's single-threaded user-mode networking, and is
    # reachable from a guest service account. Measured at 1.5 GB/s writing from
    # the guest. Re-enable guestShare for a guest that lacks the driver.
    guestFilesystems.win11.share.source = "/mnt/data/share";
    # Remote Desktop as a fallback console. The guest has no virtual GPU at all,
    # so Looking Glass is normally the only way in, and it goes dark whenever
    # Windows is running setup or the NVIDIA driver is being reinstalled.
    userNetPortForwards.win11 = [
      {
        hostPort = 13389;
        guestPort = 3389;
      }
    ];
  };

  mySystem.core.vfio = {
    enable = true;
    # 01:00.0 GB206 [GeForce RTX 5060 Ti], 01:00.1 GB206 HD Audio Controller.
    gpuIDs = ["10de:2d04" "10de:22eb"];
    lookingGlass = {
      enable = true;
      # Removes one copy from the frame path: the guest DMAs straight into a
      # host-visible buffer instead of both sides going through a /dev/shm file.
      # The guest XML must attach /dev/kvmfr0 through <qemu:commandline>, since
      # <shmem> cannot name a device node.
      kvmfr = true;
      # 3440x1440 at 32bpp is 18.9 MiB per frame; double buffering plus the LGMP
      # header needs about 48 MiB, so 128 leaves plenty of headroom.
      sizeMB = 128;
    };
  };

  # Native Linux gaming: hands the RTX 5060 Ti back to the host. Everything the
  # vfio module does is gated on its own enable flag, so turning that off is
  # enough to undo the binding, the NVIDIA blacklist and the kernel parameters
  # in one go, and lets hosts/ninja/nvidia.nix apply normally again.
  specialisation.gaming.configuration = {
    system.nixos.tags = ["gaming"];
    mySystem.core.vfio.enable = lib.mkForce false;
  };
}
