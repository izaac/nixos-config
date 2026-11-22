# YubiKey & OpenPGP Architecture

> **Last Updated**: 2026-11-21 **Hardware**: YubiKey 5.7.1 (OpenPGP applet 3.4) **Hosts**: ninja,
> Mac, snail

---

## Documentation Links

- [OpenPGP Applet Anatomy](gpg-applet.md)
- [Host Configuration (ninja, Mac, snail)](hosts.md)
- [Git Commit & Tag Signing](git-signing.md)
- [SOPS Break-Glass Decryption](sops-break-glass.md)
- [Backup, Paperkey & Master Key Strip](backup-recovery.md)
- [Secrets Overview](../secrets.md)
- [Security & Hardening](../security.md)

---

## Purpose

This documentation set covers the hardware-backed OpenPGP and U2F setup built around a single
YubiKey 5 (firmware 5.7.1, serial `27683426`, OpenPGP applet 3.4). The card holds three dedicated
RSA-4096 subkeys for daily signing, decryption, and authentication, plus a PAM U2F credential for
local workstation login and privilege escalation.

The architecture satisfies four operational goals:

1. **Hardware-isolated daily operations**: Commit signing, tag signing, and secret decryption
   require physical presence (capacitive touch) and the card User PIN. Subkey private material
   cannot be exported from the YubiKey.
2. **Unattended NixOS boot**: Host activation on `ninja` decrypts `secrets/common.yaml` via the host
   SSH key (`/etc/ssh/ssh_host_ed25519_key` derived to `age`). The YubiKey is never required at
   boot.
3. **Break-glass secret recovery**: Every SOPS secret file is encrypted to the YubiKey encryption
   subkey in addition to the host and user `age` keys. If all workstations are lost, the YubiKey
   plus a `git clone` of this repository recovers every secret.
4. **Offline master identity**: The primary certification key (`escESCA`) is backed up to paper
   (`paperkey`) and encrypted file storage, and is scheduled to be stripped from the live keyring on
   `ninja` once the offline USB medium is in hand.

---

## Threat Model

| Asset                                  | Where It Lives                                                              | Protected By                                        | Impact If Compromised                                                                                                                      |
| :------------------------------------- | :-------------------------------------------------------------------------- | :-------------------------------------------------- | :----------------------------------------------------------------------------------------------------------------------------------------- |
| **Primary Key (`33AB684C`)**           | Offline backup (`~/gpg-master.asc` pending strip, plus `paperkey` printout) | Passphrase + physical safe                          | Attacker can mint or revoke subkeys, add UIDs, or forge identity certifications. Cannot decrypt SOPS secrets wrapped to subkey `44262BC0`. |
| **Signing Subkey (`563EE61E`)**        | YubiKey Slot 1 (Signature)                                                  | User PIN (6+ digits) + touch (`cached` 15s)         | None unless physical card and User PIN are both stolen. Used for Git commits and tags.                                                     |
| **Encryption Subkey (`44262BC0`)**     | YubiKey Slot 2 (Encryption)                                                 | User PIN (6+ digits) + touch (`on` every operation) | Decrypts `secrets/common.yaml` and any PGP-encrypted payload. Requires physical card, User PIN, and one physical touch per decryption.     |
| **Authentication Subkey (`591778E2`)** | YubiKey Slot 3 (Authentication)                                             | User PIN (6+ digits) + touch (`cached` 15s)         | SSH / GPG authentication where configured. Requires physical card, User PIN, and touch.                                                    |
| **PAM U2F Credential**                 | YubiKey FIDO2/U2F applet (`~/.config/Yubico/u2f_keys`)                      | Physical touch (`control=sufficient`, no PIN)       | Local console/greeter login (`greetd`, `login`) and `sudo` on `ninja` when physically plugged in.                                          |
| **Host & User `age` Keys**             | `/etc/ssh/ssh_host_ed25519_key`, `~/.config/sops/age/keys.txt`              | LUKS / FileVault + filesystem permissions (`0600`)  | Decrypts SOPS secrets without touch. Rotated via `.sops.yaml` and `sops updatekeys` if a machine is lost.                                  |

---

## Key & Hardware Inventory

### YubiKey Hardware Summary

| Property                          | Value                                                                           |
| :-------------------------------- | :------------------------------------------------------------------------------ |
| **Device**                        | YubiKey 5 Series                                                                |
| **Firmware**                      | `5.7.1`                                                                         |
| **Serial Number**                 | `27683426`                                                                      |
| **OpenPGP Applet Version**        | `3.4`                                                                           |
| **PIN Retry Counters**            | `10 / 10 / 10` (User PIN / Reset Code / Admin PIN)                              |
| **Reset Code**                    | Configured                                                                      |
| **KDF (Key Derivation Function)** | `off`                                                                           |
| **Touch Policies**                | Signature: `cached`, Encryption: `on`, Authentication: `cached`                 |
| **PAM U2F Mapping**               | `~/.config/Yubico/u2f_keys` (`control=sufficient` on `login`, `sudo`, `greetd`) |

### OpenPGP Key Inventory

**Primary Key (Identity & Certification):**

- **Algorithm**: `rsa4096`
- **Fingerprint**: `12D77955660CBE15071B7DB73183124333AB684C`
- **Long Key ID**: `3183124333AB684C` (`gitKey = "0x3183124333AB684C"` in `lib/user.nix`)
- **Created**: `2024-03-12`
- **Expires**: `2029-02-06`
- **Capabilities**: `escESCA` (primary used for certification and identity management)
- **UIDs**:
  - `Izaac Zavaleta <izaac@linux.com>`
  - `Izaac Zavaleta <izaac.zavaleta@suse.com>`

**Card-Resident Subkeys:**

| Slot       | Role                   | Algorithm | Key ID             | Full Fingerprint                           | Created      | Expires      | Touch Policy   |
| :--------- | :--------------------- | :-------- | :----------------- | :----------------------------------------- | :----------- | :----------- | :------------- |
| **Slot 1** | Signature (`[S]`)      | `rsa4096` | `54321CB1563EE61E` | `78646A6070F607A2E3B7F21754321CB1563EE61E` | `2026-11-21` | `2028-11-20` | `cached` (15s) |
| **Slot 2** | Encryption (`[E]`)     | `rsa4096` | `D1034A1D44262BC0` | `F75D7454EBD98675753B0813D1034A1D44262BC0` | `2026-11-21` | `2028-11-20` | `on` (always)  |
| **Slot 3** | Authentication (`[A]`) | `rsa4096` | `E5C447A6591778E2` | `DC3A22E8DD269142CA474ABCE5C447A6591778E2` | `2026-11-21` | `2028-11-20` | `cached` (15s) |

---

## How the Pieces Fit Together

```text
                ┌──────────────────────────────────────────────────────┐
                │  Primary Key: 12D77955660CBE15071B7DB73183124333AB684C │
                │  Created: 2024-03-12          Expires: 2029-02-06    │
                │  Backed up to: ~/gpg-master.asc + 2-page paperkey    │
                └──────────────────────────┬───────────────────────────┘
                                           │ certifies
            ┌──────────────────────────────┼──────────────────────────────┐
            ▼                              ▼                              ▼
┌───────────────────────┐      ┌───────────────────────┐      ┌───────────────────────┐
│ Slot 1: Signature [S] │      │ Slot 2: Encryption[E] │      │ Slot 3: Auth [A]      │
│ 54321CB1563EE61E      │      │ D1034A1D44262BC0      │      │ E5C447A6591778E2      │
│ Touch: cached (15s)   │      │ Touch: on (every op)  │      │ Touch: cached (15s)   │
└───────────┬───────────┘      └───────────┬───────────┘      └───────────┬───────────┘
            │                              │                              │
            ▼                              ▼                              ▼
  Git commits & tags             SOPS break-glass               Authentication
  (commit 285f746...)            (secrets/common.yaml)          workflows
```

1. **Card Operations ([gpg-applet.md](gpg-applet.md))**: The three subkeys were moved into the
   YubiKey OpenPGP applet via `keytocard`. Local keyrings hold `sec>` / `ssb>` stubs pointing to
   card serial `27683426`.
2. **Host Integration ([hosts.md](hosts.md))**:
   - `ninja` (NixOS workstation) runs `services.pcscd` and sets
     `programs.gpg.scdaemonSettings.disable-ccid = true` in `home/dev.nix` so `scdaemon` and `pcscd`
     do not fight over USB CCID access.
   - `Mac` (nix-darwin) uses Homebrew cask `gpg-suite-no-mail` and `pinentry_mac`.
   - `snail` (Slackware 15.0-current) uses `pcscd` with a custom Polkit rule
     (`/etc/polkit-1/rules.d/20-pcsc-plugdev.rules`) allowing group `plugdev` over SSH, plus
     `pinentry-tty`.
3. **Git Signing ([git-signing.md](git-signing.md))**: Git is configured with
   `user.signingkey = 0x3183124333AB684C` and `commit.gpgsign = true`. GnuPG automatically selects
   the card-resident signing subkey `54321CB1563EE61E`.
4. **SOPS Break-Glass ([sops-break-glass.md](sops-break-glass.md))**: `.sops.yaml` places
   `*user_ninja`, `*user_mac`, `*host_ninja`, and `*yubikey` inside a single `key_groups` entry
   (boolean OR). Boot uses `/etc/ssh/ssh_host_ed25519_key` silently; emergency recovery uses subkey
   `D1034A1D44262BC0` on the YubiKey.
5. **Backups & Primary Key Strip ([backup-recovery.md](backup-recovery.md))**: The primary secret
   key is exported to `~/gpg-master.asc` (passphrase-protected, `0600`) and printed on paper via
   `paperkey` (89 lines, 2 pages, verified via round-trip restore). Once copied to an offline flash
   drive, the primary secret key is deleted from `ninja`, leaving only a `sec#` stub.

---

## Implementation Status (2026-11-21)

| Task                                                                          | Status      | Notes                                                                                 |
| :---------------------------------------------------------------------------- | :---------- | :------------------------------------------------------------------------------------ |
| Mint RSA-4096 `[S]`, `[E]`, `[A]` subkeys (expiry `2028-11-20`)               | **Done**    | Created `2026-11-21` under primary `33AB684C`                                         |
| Move subkeys to YubiKey 5.7.1 (`27683426`) via `keytocard`                    | **Done**    | Slots 1, 2, 3 populated and verified                                                  |
| Configure PINs, Reset Code, retries (`10/10/10`), and touch policies          | **Done**    | `sig=cached`, `dec=on`, `aut=cached`                                                  |
| Fix `ninja` CCID contention (`disable-ccid = true` in `home/dev.nix`)         | **Done**    | Committed in `285f746`                                                                |
| Add YubiKey to `.sops.yaml` and re-encrypt `secrets/common.yaml`              | **Done**    | Wrapped to subkey `D1034A1D44262BC0` (commit `285f746`)                               |
| Configure Slackware host `snail` (`pcscd` + Polkit rule + `pinentry-tty`)     | **Done**    | Tested over SSH with `gpg --card-status` and test sign                                |
| Publish updated public key (with subkeys) to GitHub and `keys.openpgp.org`    | **Done**    | UID email verification completed                                                      |
| Print 2-page `paperkey` backup and verify round-trip restore                  | **Done**    | 89 lines printed and tested in a scratch `GNUPGHOME`                                  |
| Export `~/gpg-master.asc` and `~/gpg-revoke.asc` (`chmod 600`)                | **Done**    | Currently on `ninja` home directory                                                   |
| Refresh stale key on `keyserver.ubuntu.com`                                   | **Pending** | Still serves old subkey-less copy; resend command in [git-signing.md](git-signing.md) |
| Copy `~/gpg-master.asc`, `~/gpg-revoke.asc`, `pub.asc` to offline flash drive | **Pending** | Awaiting dedicated offline USB storage medium                                         |
| Strip live primary secret key (`gpg --delete-secret-keys`) from `ninja`       | **Pending** | Gated on offline flash drive backup completion                                        |
