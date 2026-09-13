# GPU passthrough for the Windows 11 VM.
#
# The RTX 5060 Ti cannot serve the host and a guest at the same time, so the
# passthrough configuration lives in a specialisation instead of replacing the
# normal desktop. Limine renders every generation as a submenu containing
# "Default" plus one entry per specialisation, and both are regenerated on each
# rebuild, so the two configurations stay in sync automatically.
#
# Default entry: host drives the RTX 5060 Ti through the NVIDIA driver.
# vfio entry:    host falls back to the Ryzen iGPU, the RTX 5060 Ti and its
#                audio function are bound to vfio-pci and handed to the guest.
#
# IOMMU group 12 holds only 01:00.0 and 01:00.1, and the card advertises FLR,
# so no ACS override or reset workaround is required.
#
# BIOS prerequisites for the vfio entry: integrated graphics enabled and
# selected as the primary display, SVM and IOMMU on, and the monitor connected
# to the motherboard output.
_: {
  # libvirt is available in both entries so the guest can be prepared and its
  # disk imported without rebooting into the passthrough configuration.
  mySystem.core.libvirt.enable = true;

  specialisation.vfio.configuration = {
    system.nixos.tags = ["vfio"];

    mySystem.core.vfio = {
      enable = true;
      # 01:00.0 GB206 [GeForce RTX 5060 Ti], 01:00.1 GB206 HD Audio Controller.
      gpuIDs = ["10de:2d04" "10de:22eb"];
      # Keep the host kernel from hosts/ninja/kernel.nix without forcing a stock kernel.
      lookingGlass = {
        enable = true;
        sizeMB = 128;
      };
    };
  };
}
