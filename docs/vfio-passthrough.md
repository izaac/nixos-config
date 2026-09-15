# GPU Passthrough (ninja)

> **Status**: working. RTX 5060 Ti passed through to a Windows 11 guest, displayed on the host
> through Looking Glass. Host desktop runs on a secondary RX 550. **Config**:
> `modules/core/vfio.nix`, `modules/core/libvirt.nix`, `hosts/ninja/vfio.nix`,
> `home/looking-glass.nix`.

---

## Why

Some Windows games do not run under Wine, and a plain QEMU guest has no usable 3D. Handing the real
GPU to a Windows guest gives native driver behaviour with no translation layer, at the cost of the
card being unavailable to the host while the guest owns it.

## The two boot entries

The RTX 5060 Ti cannot serve the host and a guest at the same time, so the machine has two
configurations and Limine picks between them at boot.

| Entry       | RTX 5060 Ti         | Host desktop | Guest      |
| ----------- | ------------------- | ------------ | ---------- |
| **Default** | bound to `vfio-pci` | RX 550       | full speed |
| **gaming**  | host NVIDIA driver  | RTX 5060 Ti  | not usable |

Passthrough is the top-level configuration and native gaming is the specialisation, rather than the
other way round. Limine numbers its menu entries including submenus, so the generated
`default_entry` always lands on the newest generation's top-level leaf. Making passthrough the
default is the only way to have it selected without fighting the bootloader.

Everything in `modules/core/vfio.nix` is gated on one enable flag, so the specialisation only needs
to force that flag off to undo the binding, the NVIDIA blacklist and the kernel parameters in one
go.

## Seeing the guest

The guest has no virtual GPU at all. Looking Glass reads the real framebuffer out of shared memory
and draws it in a host window:

```bash
windows-vm        # starts the guest if needed, then attaches
```

Hold ScrollLock for the on-screen menu; ScrollLock alone toggles input capture.

The shared buffer is `/dev/kvmfr0`, a device rather than a file in `/dev/shm`. The difference is one
memory copy per frame: a device can be exported as a DMABUF and imported straight by the host GPU,
where a plain file cannot, so the client has to copy the frame before uploading it. At 3440x1440
that copy is about 19 MiB every frame.

RDP is the fallback for when Looking Glass goes dark, which is every Windows setup and every NVIDIA
driver install:

```bash
remmina -c rdp://<user>@127.0.0.1:13389
```

## Sharing files

`/mnt/data/share` is mounted in the guest as `Z:` over virtiofs. It needs no account, is not bound
by QEMU's user-mode networking, and runs at about 1.5 GB/s.

The share is on `/mnt/data`, a separate unencrypted disk. The home directory is on the LUKS root and
is deliberately out of reach of the guest.

An SMB alternative is still implemented (`mySystem.core.libvirt.guestShare`) for a guest that lacks
the virtio-fs driver. Windows needs WinFsp and the virtio-fs driver from virtio-win before virtiofs
works at all.

## Memory

The guest's 16 GiB comes from hugetlb pages of 1 GiB reserved at boot, so the whole guest is covered
by 16 page table entries instead of four million. That RAM leaves the host for the lifetime of the
boot whether or not a guest is running, which on 64 GiB is a fair trade.

Transparent huge pages are not an alternative here. Sharing the guest's memory, which virtiofs
requires, moves it out of anonymous memory and into shmem, and shmem's own hugepage policy defaults
to off.

## Devices

The gamepad is passed through as a USB `hostdev`, which detaches it from the host kernel entirely.
Only one side can have it: the guest takes it when it starts, and the host gets it back when the
guest shuts down. For native play, boot the `gaming` entry, where no guest is running.

A USB `hostdev` pins the bus and device number at the moment it is added, so unplugging and
replugging a device silently detaches it from the guest. Re-add it rather than editing the address:

```bash
virsh -c qemu:///system detach-device win11 dev.xml --live
virsh -c qemu:///system attach-device win11 dev.xml --live
```

## The guest definition

`hosts/ninja/guests/win11.xml` is a reference copy, not an input. Nothing reads it at build time and
rebuilds never write it.

```bash
just vm-save     # write the live definition into the repo
just vm-diff     # show how the live definition has drifted
```

It is kept by hand rather than generated because the domain is edited at runtime as part of normal
use, and because it carries UEFI variables and TPM state that cannot live in the Nix store. See
`hosts/ninja/guests/README.md`.

## Working inside the guest

`~/virtualization/libvirt/` holds small tools that talk to the QEMU guest agent, which needs no
display, no network and no credentials. That is the only way in when the display is broken, which
happens during every driver install. Its README covers the details and the traps.

## Known rough edges

- The host GPU is a cheap RX 550. It is fine for a desktop but is not meant for anything else.
- The board's integrated GPU is disabled in BIOS and is not usable as a host GPU. It wedged the
  whole machine while compositing a plain desktop, with no guest involved and nothing in the
  journal. See `hosts/ninja/vfio.nix` for the history.
- Windows updates re-enable telemetry and the Game Bar capture buffer. `debloat.ps1` in the working
  directory is idempotent and can be re-run after a feature update.
