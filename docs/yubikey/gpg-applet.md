# YubiKey OpenPGP Applet Anatomy

> **Last Updated**: 2026-11-21 **Hardware**: YubiKey 5.7.1 (OpenPGP applet 3.4) **Hosts**: ninja,
> Mac, snail

---

## Documentation Links

- [YubiKey & OpenPGP Overview](README.md)
- [Host Configuration (ninja, Mac, snail)](hosts.md)
- [Git Commit & Tag Signing](git-signing.md)
- [SOPS Break-Glass Decryption](sops-break-glass.md)
- [Backup, Paperkey & Master Key Strip](backup-recovery.md)

---

## Warning: Never Reset the OpenPGP Applet

> **CRITICAL**: Never run `ykman openpgp reset` on card serial `27683426`. The three subkeys
> (`54321CB1563EE61E`, `D1034A1D44262BC0`, `E5C447A6591778E2`) live **only** inside the YubiKey
> OpenPGP applet. They were moved with `keytocard` and are not included in `~/gpg-master.asc` or the
> `paperkey` printout. Resetting the OpenPGP applet permanently destroys all three subkeys,
> rendering `secrets/common.yaml` undecryptable via the card until new subkeys are minted from the
> offline master key and all SOPS files are rekeyed.

---

## PIN Architecture: User PIN, Admin PIN, and Reset Code

The OpenPGP smartcard specification defines three separate secrets with distinct lengths, retry
counters, and permissions.

| Credential            | Minimum Length                            | Factory Default                               | Configured Retries | What It Protects                                                                                                        | When Prompted                                                                                                       |
| :-------------------- | :---------------------------------------- | :-------------------------------------------- | :----------------- | :---------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------ |
| **User PIN** (`PW1`)  | **6+ characters** (6 to 127 ASCII/digits) | `123456`                                      | `10`               | Daily cryptographic operations: signing, decryption, authentication                                                     | Every `git commit`, `git tag -s`, `sops` decrypt, or `gpg --sign` / `--decrypt` (once per `gpg-agent` cache window) |
| **Reset Code**        | **8+ characters**                         | None (unset) by default, **set on this card** | `10`               | Unblocking a locked User PIN without requiring the Admin PIN                                                            | Only inside `gpg --card-edit` -> `passwd` -> `unblock`                                                              |
| **Admin PIN** (`PW3`) | **8+ characters** (8 to 127 ASCII/digits) | `12345678`                                    | `10`               | Card administration: `keytocard`, changing touch policy, setting KDF, resetting User PIN, modifying cardholder metadata | `gpg --edit-key` (`keytocard`), `gpg --card-edit` (`admin` commands), and `ykman openpgp keys set-touch`            |

### Why Admin Is 8+ Digits and User Is 6+ Digits

The ISO/IEC 7816-4 and OpenPGP Card 3.4 specifications enforce a minimum length of 6 bytes for `PW1`
(User PIN) and 8 bytes for `PW3` (Admin PIN) and the Reset Code. If you enter a 6-digit User PIN
into an Admin PIN prompt, the applet immediately rejects it (or decrements the Admin retry counter).

### The Golden Rule of PIN Prompts

- **`gpg` sign, decrypt, and ssh-auth always want the User PIN.**
- **`ykman openpgp ...` and `gpg` `keytocard` / `card-edit` admin actions always want the Admin
  PIN.**

Typing the Admin PIN into a daily signing prompt, or typing the User PIN into
`ykman openpgp keys set-touch`, returns `Bad PIN` and decrements that specific counter. Check
remaining attempts at any time with `gpg --card-status` (`PIN retry counter : 10 10 10`).

---

## Slot Mapping

The OpenPGP applet provides exactly three key slots. Each slot is wired to a fixed cryptographic
capability:

| Slot       | OpenPGP Role           | Capability                         | Subkey ID          | Full Fingerprint                           | Created      | Expires      |
| :--------- | :--------------------- | :--------------------------------- | :----------------- | :----------------------------------------- | :----------- | :----------- |
| **Slot 1** | Signature (`sig`)      | `[S]` Sign commits, tags, files    | `54321CB1563EE61E` | `78646A6070F607A2E3B7F21754321CB1563EE61E` | `2026-11-21` | `2028-11-20` |
| **Slot 2** | Encryption (`dec`)     | `[E]` Decrypt SOPS secrets & files | `D1034A1D44262BC0` | `F75D7454EBD98675753B0813D1034A1D44262BC0` | `2026-11-21` | `2028-11-20` |
| **Slot 3** | Authentication (`aut`) | `[A]` Authenticate (SSH / PAM)     | `E5C447A6591778E2` | `DC3A22E8DD269142CA474ABCE5C447A6591778E2` | `2026-11-21` | `2028-11-20` |

---

## Touch Policies (UIF: User Interaction Flag)

YubiKey 5 firmware supports physical capacitive touch requirements per OpenPGP slot, preventing
silent background operations by malware even after the User PIN is cached by `gpg-agent`.

### Available Policies

| Policy         | Behavior                                                                                                         | Can Be Changed With Admin PIN? |
| :------------- | :--------------------------------------------------------------------------------------------------------------- | :----------------------------- |
| `off`          | No physical touch required; PIN alone authorizes operations.                                                     | Yes                            |
| `on`           | Physical touch required for **every single operation**.                                                          | Yes                            |
| `cached`       | Physical touch required once, then cached on the card for **15 seconds** for subsequent operations on that slot. | Yes                            |
| `fixed`        | Same as `on`, but permanently locked until applet reset.                                                         | No                             |
| `cached-fixed` | Same as `cached`, but permanently locked until applet reset.                                                     | No                             |

### Configured Values on Card `27683426`

| Slot               | Role           | Configured Policy | Rationale                                                                                                |
| :----------------- | :------------- | :---------------- | :------------------------------------------------------------------------------------------------------- |
| **Slot 1 (`sig`)** | Signature      | `cached`          | A single touch covers burst operations such as `git rebase` or signing a commit + tag within 15 seconds. |
| **Slot 2 (`dec`)** | Encryption     | `on`              | Every SOPS or file decryption demands an explicit physical touch; no 15-second reuse window.             |
| **Slot 3 (`aut`)** | Authentication | `cached`          | Prevents repeated touch prompts during rapid authentication handshakes within 15 seconds.                |

### Commands to Set and Inspect Touch Policy

Setting touch policies requires `ykman` and the **Admin PIN**:

```bash
ykman openpgp keys set-touch sig cached
ykman openpgp keys set-touch dec on
ykman openpgp keys set-touch aut cached
```

> **UIF Reporting Quirk**: Standard OpenPGP Card specifications only define a boolean User
> Interaction Flag (`on` or `off`), whereas `cached` is a Yubico vendor extension. Because of this:
>
> - `gpg --card-status` reports `UIF setting ......: Sign=on Decrypt=on Auth=on` (it shows `cached`
>   as `on`).
> - `ykman openpgp info` queries the Yubico vendor byte directly and accurately reports `Cached` vs
>   `On`.

---

## KDF (Key Derivation Function)

OpenPGP Card 3.4 supports on-card KDF, which hashes the PIN on the host before sending it over USB
CCID so the raw ASCII digits never cross the bus.

- **Current Status on Card `27683426`**: `KDF setting ......: off`
- **When to Enable**: KDF can be enabled on a clean card or when resetting PINs to default, because
  enabling KDF changes the byte representation the card expects and invalidates existing raw PINs.
- **How to Enable (Reference Only)**: If resetting PINs in the future via `gpg --card-edit`:

  ```text
  gpg/card> admin
  gpg/card> kdf-setup
  ```

  Do not toggle `kdf-setup` without having the Admin PIN ready and immediately re-verifying both
  User and Admin PINs across all hosts (`ninja`, `Mac`, `snail`), as older GnuPG / scdaemon builds
  must support KDF data objects (`0xF9`).

---

## The `keytocard` Procedure (Reference)

Moving subkeys from a software keyring onto the YubiKey is a destructive move inside the active
`GNUPGHOME` once saved: the secret key parameters on disk are replaced with a card serial stub
(`ssb>`).

### Trap: `key N` Follows Listing Order, Not Slot Number

Inside `gpg --edit-key 12D77955660CBE15071B7DB73183124333AB684C`, the `key 1`, `key 2`, `key 3`
selector numbers refer to the **position of the subkey in the `gpg --edit-key` screen listing**, NOT
the YubiKey slot number (`1=Signature`, `2=Encryption`, `3=Authentication`).

When our subkeys were listed in `gpg --edit-key`, their display order was:

1. `key 1`: `E5C447A6591778E2` (`[A]` Authentication) -> moved to **Slot 3 (Authentication)**
2. `key 2`: `54321CB1563EE61E` (`[S]` Signing) -> moved to **Slot 1 (Signature)**
3. `key 3`: `D1034A1D44262BC0` (`[E]` Encryption) -> moved to **Slot 2 (Encryption)**

Also remember to run `key <N>` a second time to **deselect** the previous subkey before selecting
the next one (an asterisk `ssb*` marks each currently selected subkey).

### Step-by-Step Sequence Used

```text
$ gpg --edit-key 12D77955660CBE15071B7DB73183124333AB684C

gpg> key 1
# Verify the * appears on subkey E5C447A6591778E2 [A]
gpg> keytocard
Please select where to store the key:
   (3) Authentication key
Your selection? 3
# Prompted for key passphrase, then Admin PIN

gpg> key 1
# Deselect key 1
gpg> key 2
# Verify the * appears on subkey 54321CB1563EE61E [S]
gpg> keytocard
Please select where to store the key:
   (1) Signature key
   (3) Authentication key
Your selection? 1
# Prompted for key passphrase, then Admin PIN

gpg> key 2
# Deselect key 2
gpg> key 3
# Verify the * appears on subkey D1034A1D44262BC0 [E]
gpg> keytocard
Please select where to store the key:
   (2) Encryption key
Your selection? 2
# Prompted for key passphrase, then Admin PIN

gpg> save
```

Always make an offline backup of the primary key (`~/gpg-master.asc`) **before** running `keytocard`
and `save`.

---

## Verification Commands

### 1. Check GnuPG Card Status and Local Stubs

```bash
gpg --card-status
```

Expected output fields:

```text
Reader ...........: Yubico YubiKey OTP FIDO CCID 00 00
Application ID ...: D2760001240103040006276834260000
Application type .: OpenPGP
Version ..........: 3.4
Manufacturer .....: Yubico
Serial number ....: 27683426
PIN retry counter : 10 10 10
KDF setting ......: off
UIF setting ......: Sign=on Decrypt=on Auth=on
Signature key ....: 7864 6A60 70F6 07A2 E3B7  F217 5432 1CB1 563E E61E
      created ....: 2026-11-21 00:54:51
Encryption key....: F75D 7454 EBD9 8675 753B  0813 D103 4A1D 4426 2BC0
      created ....: 2026-11-21 00:55:27
Authentication key: DC3A 22E8 DD26 9142 CA47  4ABC E5C4 47A6 5917 78E2
      created ....: 2026-11-21 00:55:49
```

### 2. Check YubiKey Applet Info and Touch Policies

```bash
ykman openpgp info
```

Expected output:

```text
OpenPGP version:            3.4
Application version:        5.7.1
PIN tries remaining:        10
Reset code tries remaining: 10
Admin PIN tries remaining:  10
Require PIN for signature:  Once
KDF enabled:                False

Touch policies
Signature key:              Cached
Encryption key:             On
Authentication key:         Cached
Attestation key:            Off
```

### 3. Check Secret Keyring Markers (`ssb>`)

```bash
gpg --list-secret-keys --keyid-format=long 12D77955660CBE15071B7DB73183124333AB684C
```

- `ssb>` indicates the secret subkey is a smartcard stub pointing to card `27683426`.
- `sec` indicates the primary secret key is currently present on disk (before the strip).
- `sec#` indicates the primary secret key has been stripped from disk (the target state after
  offline flash backup).
