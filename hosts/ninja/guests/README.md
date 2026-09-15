# Guest definitions

Reference copies of the libvirt domains on this host. They are documentation and a recovery point,
not an input to the build: nothing in the flake reads them, and `nixos-rebuild` never writes them.

## Why these are not generated from Nix

[NixVirt](https://github.com/AshleyYakeley/NixVirt) is maintained and would generate these from Nix
attribute sets, but it is the wrong tool for this guest. The domain is edited at runtime as part of
normal use: the gamepad is attached and detached with `virsh attach-device --config` whenever it
moves between the host and the guest, and `<video>` is temporarily switched from `none` to `qxl` to
make Windows setup visible. Under NixVirt those edits would be silently reverted by the next
rebuild.

The domain also carries state that must not live in the Nix store: the UEFI variables in
`/var/lib/libvirt/qemu/nvram/win11_VARS.fd` and the swtpm state backing the TPM that Windows 11
requires.

## Keeping them current

    just vm-save     # write the live definition here
    just vm-diff     # show how the live definition differs

`virsh dumpxml --inactive` is the right source. It emits the configuration that will be used on the
next start rather than the running one, and it round-trips exactly: feeding the output back to
`virsh define` and dumping again reproduces it byte for byte, so a diff against this file is
meaningful.

Do not be tempted by `--migratable`. It is for migration, not backup, and strips anything the
destination host might supply itself. On this domain it drops the `firmware='efi'` attribute and its
whole `<firmware>` block, the watchdog, the SPICE audio backend and the PS/2 keyboard.

## Restoring

    virsh -c qemu:///system define hosts/ninja/guests/win11.xml

This rebuilds the domain only. The disk at `/mnt/data/vms/win11.qcow2`, the NVRAM file and the swtpm
state are all separate and are not backed up here.

## Contents

Checked before committing: no `<secret>`, no `passwd` attribute, no `<sysinfo>` or `<smbios>` block,
and SPICE listens on `127.0.0.1` with no password. The domain UUID and the MAC address are the only
identifiers. Neither is a credential, the MAC is in QEMU's locally administered `52:54:00` range
behind user-mode NAT, and the UUID must not be regenerated because QEMU passes it to the guest as
the SMBIOS system UUID, which Windows activation hashes.
