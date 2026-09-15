# Take virtiofsd from nixos-unstable rather than the 26.05 release branch.
#
# virtiofs and Looking Glass's kvmfr module could not be used together until
# very recently. vhost-user hands every guest memory region to virtiofsd, which
# sized each one by way of vm-memory's check_file_offset(). That helper called
# lseek(fd, 0, SEEK_END), and /dev/kvmfr0 is a character device with no llseek,
# so the daemon died with ESPIPE ("Illegal seek") as soon as the guest started.
#
# The check was removed outright in rust-vmm/vm-memory#320, on the grounds that
# the kernel validates the mapping during mmap anyway and the check rejected
# legitimate cases such as VFIO devices and guest_memfd. That reached virtiofsd
# through the dependency bump in virtio-fs/virtiofsd!306, closing its issue #96,
# and shipped in virtiofsd 1.14.0. kvmfr itself was never changed.
#
# 26.05 still carries 1.13.3, which predates the bump, so the two remain
# mutually exclusive on the release branch.
#
# Safe to take from unstable: virtiofsd is a standalone daemon that libvirt
# execs by path, with no kernel module and no coupling to the rest of the
# system. It is evaluated against unstable's own pkgs set, so no stdenv mixing.
# Drop this overlay once 26.11 ships 1.14.0 or newer.
inputs: final: _prev: {
  virtiofsd = inputs.nixpkgs-unstable.legacyPackages.${final.stdenv.hostPlatform.system}.virtiofsd;
}
