# Backup, Paperkey, Master Key Strip & Troubleshooting

> **Last Updated**: 2026-11-21 **Hardware**: YubiKey 5.7.1 (OpenPGP applet 3.4) **Hosts**: ninja,
> Mac, snail

---

## Documentation Links

- [YubiKey & OpenPGP Overview](README.md)
- [OpenPGP Applet Anatomy](gpg-applet.md)
- [Host Configuration (ninja, Mac, snail)](hosts.md)
- [Git Commit & Tag Signing](git-signing.md)
- [SOPS Break-Glass Decryption](sops-break-glass.md)

---

## Backup Inventory (What Exists Today)

| Artifact                | Location (Current)                                         | Permissions   | Contents                                                                                              | Passphrase Protected?                                                                        |
| :---------------------- | :--------------------------------------------------------- | :------------ | :---------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------- |
| **`gpg-master.asc`**    | Offline keypad drive (local copy shredded 2026-11-21)      | `0600`        | Armored **primary secret key only** (`--export-secret-keys 12D77955660CBE15071B7DB73183124333AB684C`) | **Yes** (master key passphrase)                                                              |
| **`gpg-revoke.asc`**    | Offline keypad drive (local copy shredded 2026-11-21)      | `0600`        | Armored revocation certificate for primary key `33AB684C`                                             | No (pre-signed revocation packet; keep secret)                                               |
| **`pub.asc`**           | Public keyservers (`keys.openpgp.org`), GitHub, local copy | `0644`        | Public primary key + UIDs + all three public subkey binding certificates (`[S]`, `[E]`, `[A]`)        | No (public data, required by `paperkey` restore)                                             |
| **`paperkey` Printout** | Physical paper (2 pages, 89 lines)                         | Physical safe | Hex + CRC24 dump of the secret MPIs of primary key `33AB684C`                                         | **Yes** (S2K salt, cipher, and encrypted MPIs preserved directly from the secret key packet) |

### Commands Used to Produce the Backups

```bash
# 1. Export the primary secret key ONLY (after subkeys were moved to card, or via --export-secret-key)
umask 077
gpg --armor --export-secret-keys 12D77955660CBE15071B7DB73183124333AB684C > ~/gpg-master.asc
chmod 600 ~/gpg-master.asc

# 2. Generate a standalone revocation certificate
gpg --output ~/gpg-revoke.asc --gen-revoke 12D77955660CBE15071B7DB73183124333AB684C
chmod 600 ~/gpg-revoke.asc

# 3. Export the full public key (required to reconstruct the key from paperkey)
gpg --armor --export 12D77955660CBE15071B7DB73183124333AB684C > ~/pub.asc
```

---

## Paperkey Anatomy & Round-Trip Restore

### What `paperkey` Contains (and What It Cannot Do)

An OpenPGP secret key file (`~/gpg-master.asc`) is roughly 80% public metadata (public RSA modulus
`n`, exponent `e`, UID strings, self-signatures, and subkey public packets). `paperkey` strips away
every public byte and outputs only the encrypted secret Multi-Precision Integers (MPIs: `d`, `p`,
`q`, `u`) along with the String-to-Key (S2K) iteration/salt header and per-line CRC-24 checksums.

- **Length**: 89 lines across 2 printed pages for our RSA-4096 primary key.
- **Passphrase protection is preserved**: The secret MPIs on the paper remain encrypted under your
  master GPG passphrase. Anyone who finds the 2-page printout still cannot use the key without the
  passphrase.
- **What `paperkey` CANNOT do**:
  1. It **cannot reconstruct your key without a copy of the public key (`pub.asc` / `pub.gpg`)**.
     The public key supplies the public modulus, UIDs, and packet framing that `paperkey --pubring`
     merges with the secret MPIs. Always keep `pub.asc` on GitHub and keyservers.
  2. It **does not contain the three YubiKey subkeys** (`54321CB1563EE61E`, `D1034A1D44262BC0`,
     `E5C447A6591778E2`), because those were moved to the card before `paperkey` ran (only their
     dummy card stubs `ssb>` remain on disk).
  3. It **cannot decrypt SOPS ciphertext** (`secrets/common.yaml`) wrapped to card subkey
     `D1034A1D44262BC0`. Paper restores your **OpenPGP identity** so you can revoke lost subkeys and
     mint new ones; it never decrypts card-wrapped data.

### Generating `paperkey` Output

> **Gotcha**: `paperkey` requires **binary (dearmored)** OpenPGP packets. Passing an ASCII-armored
> `.asc` file directly to `paperkey --secret-key` fails with `unable to parse OpenPGP packets`.
> Always pipe through `gpg --dearmor` or export without `--armor`.

```bash
gpg --dearmor < ~/gpg-master.asc | paperkey --output ~/gpg-master-paperkey.txt
wc -l ~/gpg-master-paperkey.txt
# 89 /home/izaac/gpg-master-paperkey.txt
```

### Printing and Storing the Paper Key

Print from the generated file, check the layout, then destroy the file. The printout is the backup,
the file is not.

```bash
umask 077
D="$(mktemp -d)"; chmod 700 "$D"
gpg --dearmor < ~/gpg-master.asc > "$D/master.gpg"
gpg --export 12D77955660CBE15071B7DB73183124333AB684C > "$D/pub.gpg"
paperkey --secret-key "$D/master.gpg" --output "$D/master.paperkey"
wc -l "$D/master.paperkey"                                  # expect 89
awk 'length > 78 {print NR": "length}' "$D/master.paperkey" # must print nothing
lp -d Canon_LBP113 "$D/master.paperkey"                     # adjust to your queue
```

Check before shredding:

- both pages printed, in order, and page two ends at line 89
- no line wrapped or clipped at the margin, the `awk` above is the machine check
- the restore test in the next section prints `sec` without `#`

Then remove the working copies:

```bash
shred -u "$D/master.paperkey" "$D/master.gpg"
rm -rf "$D"
```

Storage: split the two pages across two locations if you want a single found page to be useless, and
keep `pub.gpg` or `pub.asc` with each half. Never photograph it, never scan it to a cloud drive,
never leave it in a printer tray.

### Copying the Set to the Offline Drive

```bash
lsblk -o NAME,SIZE,LABEL,MOUNTPOINT                 # identify the keypad drive, do not guess
sudo mkdir -p /mnt/backup
sudo mount /dev/sdX1 /mnt/backup                    # unlock on the drive keypad first
sudo install -m 600 ~/gpg-master.asc  /mnt/backup/
sudo install -m 600 ~/gpg-revoke.asc  /mnt/backup/
sudo install -m 644 ~/pub.asc         /mnt/backup/
sha256sum ~/gpg-master.asc ~/gpg-revoke.asc ~/pub.asc /mnt/backup/*.asc
sync
sudo umount /mnt/backup
```

The checksums must match pairwise. Then run the restore gate below against the copy on the drive,
not against the copy in `/home`. Only after that prints `RESTORE_OK` is the strip in
[Primary Strip](#primary-strip-performed-2026-11-21) allowed.

### Verified Restore Procedure from Paperkey

To restore the primary secret key from the 89-line paper printout (either typed/OCR'd into
`paperkey.txt` or from a file) into a clean scratch `GNUPGHOME`:

```bash
# 1. Create an isolated scratch homedir with pinentry configured
export GNUPGHOME=/tmp/opencode/paperkey-restore
mkdir -p "$GNUPGHOME" && chmod 700 "$GNUPGHOME"
cat > "$GNUPGHOME/gpg-agent.conf" <<EOF
pinentry-program $(command -v pinentry-curses || command -v pinentry-tty || command -v pinentry)
EOF

# 2. Convert the armored public key (pub.asc) into a binary pubring file (pub.gpg)
#    paperkey --pubring also requires binary OpenPGP packets, NOT ASCII armor!
gpg --dearmor < ~/pub.asc > "$GNUPGHOME/pub.gpg"

# 3. Recombine the binary public key ring with the paperkey text and import into GPG
#    gpg --import prompts for the master key passphrase via pinentry to re-wrap into keyboxd/private-keys-v1.d
paperkey --pubring "$GNUPGHOME/pub.gpg" --secrets ~/gpg-master-paperkey.txt | gpg --import

# 4. Verify the primary secret key is fully restored (shows 'sec' without '#' or '>')
gpg --list-secret-keys --keyid-format=long

# 5. Clean up scratch homedir after testing
gpgconf --kill all
rm -rf "$GNUPGHOME"
unset GNUPGHOME
```

---

## Offline Hardware Storage Options

Before stripping the primary secret key from `ninja`, `~/gpg-master.asc`, `~/gpg-revoke.asc`, and
`pub.asc` must be copied onto an offline USB flash drive stored alongside the 2-page `paperkey`
printout.

### Why Kingston IronKey Locker+ 50 G2 Was Rejected

The **Kingston IronKey Locker+ 50 (LP50 G2)** relies on a software-activated virtual CD-ROM unlocker
partition (`IronKey.exe` / `IronKey.app`). It has **no official Linux support** and requires
third-party reverse-engineered SCSI unlocker utilities to mount on NixOS or Slackware. In an
emergency recovery on Linux (`ninja`, `snail`, or a `canoe` live ISO), a backup medium that cannot
be unlocked with standard kernel drivers is a liability.

### Recommended OS-Independent Options

| Option Class                                                     | Models / Implementation                                                                                | How It Unlocks                                                                                                                                            | Pros                                                                                                                                                                                                                                                                                                                                                 | Cons / Caveats                                                                                                                                                                                                      |
| :--------------------------------------------------------------- | :----------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **1. Hardware Keypad USB (OS-Independent)**                      | **Kingston IronKey Keypad 200 (KP200)**, **iStorage datAshur Pro2**, **Apricorn Aegis Secure Key 3NX** | Physical polymer keypad on the drive itself (unlock before plugging into USB)                                                                             | Zero host software required. Enumerates as a standard USB Mass Storage block device (`ext4` or `exfat`) on NixOS, macOS, Slackware, and live ISOs. Validation level varies by model and revision (KP200 is FIPS 140-3 Level 3; datAshur Pro2 and Aegis Secure Key 3NX are FIPS 140-2 Level 3), so check the current certificate for the exact model. | Internal tiny Li-Po battery powers the keypad when unplugged; if left in a drawer for years without charging, the battery can deplete (must be plugged into a powered USB port for 30-60 minutes before unlocking). |
| **2. Plain Quality Flash Drive + `age` / OpenPGP Armor + Paper** | Standard SLC/MLC industrial USB stick (formatted `exfat` or `ext4`) + the 2-page `paperkey` printout   | Standard USB mount; files inside (`gpg-master.asc`) are already encrypted under the GPG master passphrase (plus optional outer `age -p` passphrase layer) | No battery to die, no proprietary controller firmware to lock up, works on every OS forever.                                                                                                                                                                                                                                                         | Relies on the strength of the GPG / `age` passphrase if the physical stick is stolen from the safe.                                                                                                                 |

### NAND Media Refresh & the "Read It Back Yearly" Rule

All NAND flash memory stores charge in floating-gate / charge-trap cells that slowly leak over time
when unpowered (especially in warm environments), and keypad USB drives have internal rechargeable
batteries that self-discharge.

- **Read it back yearly**: Once a year (or during the subkey renewal check), plug the offline backup
  USB drive in, unlock it, verify `sha256sum gpg-master.asc gpg-revoke.asc pub.asc`, and let keypad
  drives top up their internal battery for 30 minutes.
- Keep the **2-page `paperkey` printout** in the safe as the ultimate zero-electronics fallback.

---

### Role of Each Artifact

| Artifact                                      | What it is                                      | Role                                                               | What losing it costs                                                                                  |
| :-------------------------------------------- | :---------------------------------------------- | :----------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------- |
| **YubiKey**                                   | three private subkeys inside the OpenPGP applet | daily signing and decryption, and your sops break-glass            | Recoverable. Mint new subkeys from the primary and `keytocard` them. Does not cost the identity.      |
| **`gpg-master.asc`** (home plus offline copy) | primary secret key, passphrase protected        | the identity root: mint or revoke subkeys, add UIDs, extend expiry | Fatal. Nothing can regenerate it. Restore from paper or the drive, or the identity is gone.           |
| **`paperkey` printout**                       | same primary secret, no electronics             | the fallback when flash media, firmware or a battery fails         | Costs you the last human-readable copy of the master.                                                 |
| **`pub.asc`**                                 | public key with subkeys                         | required to rebuild from paper and to let others verify you        | Cheap. It is on keyservers, GitHub and every machine's keyring.                                       |
| **`gpg-revoke.asc`**                          | pre-signed revocation packet                    | emergency kill switch if the key or passphrase is compromised      | Regenerable while the key still works; not after.                                                     |
| **Master passphrase**                         | in your head or password manager                | unlocks the primary in `gpg-master.asc` and on the paper           | Fatal together with the paper: an unopenable backup is not a backup.                                  |
| **age keys** (`user_*`, `host_*`)             | files on each machine, never on the card        | the actual sops boot-time decryption                               | If every machine and the card are gone, the sops ciphertext is unrecoverable regardless of the paper. |

## Primary Strip: Performed 2026-11-21

> **STATUS: DONE.** `ninja` holds no primary secret key any more. The offline copy lives on the
> keypad drive, the verified `paperkey` printout is the fallback, and the local `~/gpg-master.asc`
> and `~/gpg-revoke.asc` were shredded after the strip was verified.

Verification performed at the time:

```text
gpg --card-status      Signature, Encryption, Authentication keys present
gpg -K                 sec# 3183124333AB684C, ssb> on all three subkeys
clearsign test         SIGN_OK
sops decrypt           sshHost value returned
private-keys-v1.d      primary keygrip absent, three subkeys are shadowed-private-key stubs
```

The procedure below is kept as the record of what was executed and as the reference for repeating it
after any future primary restore.

### Why Strip the Primary Key?

Before the strip, `gpg --list-secret-keys` on `ninja` showed:

- `sec   rsa4096/3183124333AB684C` (the live primary secret key file exists inside
  `~/.gnupg/private-keys-v1.d/<KEYGRIP>.key`, protected only by its passphrase).
- `ssb>  rsa4096/E5C447A6591778E2` (card stub)
- `ssb>  rsa4096/54321CB1563EE61E` (card stub)
- `ssb>  rsa4096/D1034A1D44262BC0` (card stub)

As long as `sec` (without `#`) lives on the laptop/workstation disk, an attacker who compromises
`ninja` and captures or brute-forces the passphrase can mint new subkeys, add attacker UIDs, extend
expiration dates, or revoke your identity. Daily operations (Git signing, SOPS decryption, SSH auth)
only ever touch the three `ssb>` card stubs. Stripping the primary secret key leaves `sec#` on disk
so even full root compromise of `ninja` cannot steal your OpenPGP identity.

### Exact Strip Procedure (Run Once Offline USB Backup Is Verified)

1. **Prove the offline copy, not the local file, is restorable.** `gpg --show-keys` only proves the
   armor parses. Import the USB copy into a scratch keyring and sign with it:

   ```bash
   USB=/run/media/$USER/KP200          # adjust to the mounted keypad drive
   sha256sum "$USB/gpg-master.asc" ~/gpg-master.asc    # must match

   scratch="$(mktemp -d)"; chmod 700 "$scratch"
   printf 'pinentry-program %s\n' "$(command -v pinentry-curses || command -v pinentry-tty || command -v pinentry)" > "$scratch/gpg-agent.conf"
   GNUPGHOME="$scratch" gpg --import "$USB/gpg-master.asc"
   GNUPGHOME="$scratch" gpg -K 12D77955660CBE15071B7DB73183124333AB684C   # sec, no #
   GNUPGHOME="$scratch" gpg -u 12D77955660CBE15071B7DB73183124333AB684C \
     --clearsign /dev/null > /dev/null && echo RESTORE_OK

   gpgconf --homedir "$scratch" --kill all
   shred -u "$scratch/gpg-agent.conf"; rm -rf "$scratch"
   ```

   Silence after the clearsign means the passphrase on the backup does not open the key. Do not
   strip anything until it prints `RESTORE_OK`.

2. **Delete the secret keys from the live keyring**:

   ```bash
   gpg --delete-secret-keys 12D77955660CBE15071B7DB73183124333AB684C
   ```

   (Confirm the prompts in `gpg` / `pinentry` to delete the primary secret key from disk.)

3. **Re-create the card-backed subkey stubs (`ssb>`)**: With the YubiKey plugged in, run:

   ```bash
   gpg --card-status
   ```

   GnuPG reads the three subkey fingerprints from the YubiKey, matches them against the public key
   still in your keyring, and populates `sec#` (missing primary secret) plus `ssb>` (three
   card-backed subkey stubs).

4. **Securely remove the staging files from `~/` on `ninja`** (only after confirming they live on
   the offline USB drive!):

   ```bash
   shred -u ~/gpg-master.asc ~/gpg-revoke.asc ~/gpg-master-paperkey.txt
   ```

### Post-Strip Verification Commands

```bash
# 1. Verify 'sec#' (primary stripped) and three 'ssb>' (card subkey stubs)
gpg --list-secret-keys --keyid-format=long 12D77955660CBE15071B7DB73183124333AB684C
```

Expected output after strip:

```text
sec#  rsa4096/3183124333AB684C 2024-03-12 [SC] [expires: 2029-02-06]
      12D77955660CBE15071B7DB73183124333AB684C
uid                 [ultimate] Izaac Zavaleta <izaac@linux.com>
uid                 [ultimate] Izaac Zavaleta <izaac.zavaleta@suse.com>
ssb>  rsa4096/E5C447A6591778E2 2026-11-21 [A] [expires: 2028-11-20]
ssb>  rsa4096/54321CB1563EE61E 2026-11-21 [S] [expires: 2028-11-20]
ssb>  rsa4096/D1034A1D44262BC0 2026-11-21 [E] [expires: 2028-11-20]
```

```bash
# 2. Verify daily signing still works via the YubiKey
echo "post-strip clearsign test" | gpg --clearsign

# 3. Verify break-glass SOPS decryption still works via the YubiKey
SOPS_AGE_KEY_FILE=/dev/null sops -d secrets/common.yaml > /dev/null && echo "SOPS break-glass OK"
```

### Rollback (Temporarily Restoring the Primary Key)

Whenever you need to perform a certification ceremony (extending expiry dates, minting new subkeys,
adding a UID), temporarily import `gpg-master.asc`:

```bash
gpg --import /path/to/offline-usb/gpg-master.asc
# Perform key maintenance (e.g., gpg --quick-set-expire ...)
# Re-export updated backup if primary key metadata changed, then strip again:
gpg --delete-secret-keys 12D77955660CBE15071B7DB73183124333AB684C
gpg --card-status
```

---

## Renewal Calendar & Expiration Extension Procedure

| Key / Subkeys                          | Key ID(s)                                                  | Current Expiration | Recommended Renewal Window             |
| :------------------------------------- | :--------------------------------------------------------- | :----------------- | :------------------------------------- |
| **Card Subkeys (`[S]`, `[E]`, `[A]`)** | `54321CB1563EE61E`, `D1034A1D44262BC0`, `E5C447A6591778E2` | **`2028-11-20`**   | October - November 2028                |
| **Primary Key (`[SC]`)**               | `3183124333AB684C` (`12D7...684C`)                         | **`2029-02-06`**   | Renew at the same time in Oct/Nov 2028 |

### How to Extend Expiration Dates (Without Replacing Card Keys)

Extending the expiration date of existing subkeys only updates the **public self-signature packets**
(signed by the primary key). The RSA private keys inside the YubiKey slots do **not** change and do
not need to be re-generated or re-moved with `keytocard`.

```bash
# 1. Mount the offline backup USB and import the primary secret key
gpg --import /mnt/usb/gpg-master.asc

# 2. Extend the primary key expiration by 3 years from today
gpg --quick-set-expire 12D77955660CBE15071B7DB73183124333AB684C 3y

# 3. Extend all subkeys ('*') by 2 or 3 years from today
gpg --quick-set-expire 12D77955660CBE15071B7DB73183124333AB684C 3y '*'

# 4. Verify the new [expires: YYYY-MM-DD] dates
gpg --list-keys --keyid-format=long 12D77955660CBE15071B7DB73183124333AB684C

# 5. Export and publish the updated public key (pub.asc) everywhere
gpg --armor --export 12D77955660CBE15071B7DB73183124333AB684C > pub.asc
gpg --keyserver hkps://keys.openpgp.org --send-keys 12D77955660CBE15071B7DB73183124333AB684C
gpg --keyserver hkps://keyserver.ubuntu.com --send-keys 12D77955660CBE15071B7DB73183124333AB684C
# Also paste the updated pub.asc into GitHub Settings -> SSH and GPG keys!

# 6. Strip the primary secret key from disk again and restore card stubs
gpg --delete-secret-keys 12D77955660CBE15071B7DB73183124333AB684C
gpg --card-status
```

---

### Rotating a Subkey (Replacing, Not Extending)

Extending expiry keeps the same key material. Rotating mints a new key of the same purpose and
retires the old one. Rotate when a card is lost or suspected compromised, when expiry is imminent
and you prefer fresh keys, or when upgrading hardware.

Rules that apply to all three:

- Work with the primary secret present (`gpg --import ~/gpg-master.asc`), then strip it again at the
  end.
- One subkey at a time. Get it on the card and proven before touching the next.
- Revoke the retired subkey with `revkey` rather than deleting it, otherwise signatures it already
  made can no longer be verified.
- Re-export and republish `pub.asc` afterwards: keyservers and GitHub need the new subkey.
- Never `ykman openpgp reset` mid-rotation.

**Signing (`[S]`, slot 1)**

```bash
gpg --quick-add-key 12D77955660CBE15071B7DB73183124333AB684C rsa4096 sign 2y
gpg --edit-key 12D77955660CBE15071B7DB73183124333AB684C
#   key N            # select the NEW sign subkey, verify its id in the listing
#   keytocard        # slot 1, admin PIN, slot is overwritten
#   key N            # deselect
#   key M            # select the OLD sign subkey 54321CB1563EE61E
#   revkey           # revoke it, keep it in the key for old signatures
#   save
```

Then `echo t | gpg --clearsign` and one `git commit -S` to prove the card now signs with the new
key.

**Encryption (`[E]`, slot 2) with sops**

Order matters. Rewrap the secrets while the new subkey is still local and reachable, before the old
card key is retired.

```bash
gpg --quick-add-key 12D77955660CBE15071B7DB73183124333AB684C rsa4096 encr 2y
# 1. rewrap and verify (hardened recipe in sops-break-glass.md)
#    the PGP PKESK keyid must now be the NEW encryption subkey
yq -r '.sops.pgp[0].enc' secrets/common.yaml | gpg --list-packets | grep keyid
# 2. only then move it to the card
gpg --edit-key 12D77955660CBE15071B7DB73183124333AB684C
#   key N -> keytocard -> slot 2 -> key N -> key M (old D1034A1D44262BC0) -> revkey -> save
```

Then prove break-glass still works: `SOPS_AGE_KEY_FILE=/dev/null sops -d secrets/common.yaml`.

**Authentication (`[A]`, slot 3)**

```bash
gpg --quick-add-key 12D77955660CBE15071B7DB73183124333AB684C rsa4096 auth 2y
gpg --edit-key 12D77955660CBE15071B7DB73183124333AB684C
#   key N -> keytocard -> slot 3 -> key N -> key M (old E5C447A6591778E2) -> revkey -> save
```

Only this subkey is affected: `services.gpg-agent.enableSshSupport = false` here, so SSH auth is not
in use and nothing else needs updating.

**Common close-out**

```bash
gpg --armor --export 12D77955660CBE15071B7DB73183124333AB684C > pub.asc
gpg --keyserver hkps://keys.openpgp.org --send-keys 12D77955660CBE15071B7DB73183124333AB684C
gpg --keyserver hkps://keyserver.ubuntu.com --send-keys 12D77955660CBE15071B7DB73183124333AB684C
# paste the new pub.asc into GitHub -> Settings -> SSH and GPG keys
gpg --delete-secret-keys 12D77955660CBE15071B7DB73183124333AB684C
gpg --card-status
```

Update the inventory tables in [README.md](README.md) and the calendar above with the new key ids
and expiry dates, then re-run the drive copy so the backups match reality.

### Migrating the Whole Identity to a New Token

The scenario: a Nitrokey, a second YubiKey, or a replacement card. Roughly 30 to 45 minutes. The
primary fingerprint does not change, so nothing in `.sops.yaml`, keyservers, GitHub, or other
people's keyrings needs a new identity, only a refreshed publication.

Prerequisites: verified offline backup (paper or drive), both tokens at hand, admin PIN ready on the
new token, a quiet half hour.

1. **Prepare the new token.** Set its admin PIN (8 digits), user PIN (6+), reset code, and raise
   retries to 10 with the vendor tool (`ykman openpgp access set-retries 10 10 10`, or
   `gpg --card-edit` on a standard OpenPGP card). Changing these later is another ceremony.
2. **Restore the primary.** `gpg --import /path/to/gpg-master.asc` from the offline medium.
3. **Mint fresh subkeys.** You cannot copy the old card's keys out, by design:
   `gpg --quick-add-key <fpr> rsa4096 sign 2y`, then `encr`, then `auth`.
4. **Move them to the new token**, one slot per subkey, checking the listing order as described
   above: signing to slot 1, encryption to slot 2, authentication to slot 3, `save` at the end.
5. **Re-encrypt sops before retiring the old card.** Run the hardened re-encryption recipe in
   [sops-break-glass.md](sops-break-glass.md) and confirm the PKESK keyid is the new encryption
   subkey. Skipping this leaves `secrets/common.yaml` readable only by the old card and the offline
   backup.
6. **Revoke the old subkeys.** `gpg --edit-key`, select each old subkey, `revkey`, `save`. Revoke
   rather than delete so signatures the old card already made still verify.
7. **Republish.** `gpg --armor --export <fpr>` to `keys.openpgp.org`, `keyserver.ubuntu.com`, and
   GitHub. Verifiers need the new subkeys.
8. **Re-register the non-GPG uses.** U2F/PAM (`pamu2fcfg > ~/.config/Yubico/u2f_keys`, both tokens
   may coexist during the transition), and any `ed25519-sk` SSH credential, which is disposable and
   simply gets regenerated on the new token.
9. **Verify on each host.** `gpg --card-status`, one `git commit -S`, one
   `SOPS_AGE_KEY_FILE=/dev/null sops -d secrets/common.yaml`.
10. **Strip again.** `gpg --delete-secret-keys <fpr>`, `gpg --card-status`, then confirm `sec#` plus
    three stubs. Shred the restored export.
11. **Update the record.** Inventory table, status table, expiry calendar, and the drive copy of the
    backup if the primary metadata changed (new subkeys are not in the old export).

What can go wrong, and the cost:

| Mistake                                       | Consequence                                                                      |
| :-------------------------------------------- | :------------------------------------------------------------------------------- |
| Skipping step 5                               | sops file stays wrapped to the retired card; only the offline backup can read it |
| Deleting instead of revoking old subkeys      | old signatures on commits and tags stop verifying                                |
| Forgetting step 7                             | commits show unverified, and remote hosts cannot encrypt to you                  |
| Running `ykman openpgp reset` on either token | destructive; the only recovery is the offline primary plus re-minting            |

Keeping the old token as a spare is fine for U2F, but once its subkeys are revoked it can no longer
sign or decrypt, which is the property that makes the migration trustworthy.

## Troubleshooting Reference (Real Failure Modes)

| Symptom / Error Message                                                                           | Root Cause                                                                                                                                                                                                                                                                                                                           | Fix                                                                                                                                                                                                                                                                                                                                                                                                                                          |
| :------------------------------------------------------------------------------------------------ | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`gpg: signing failed: Bad PIN`** (or `ykman` rejects PIN)                                       | Entered the wrong PIN kind: typed the 8-digit Admin PIN into a `gpg` sign/decrypt prompt, or typed the 6-digit User PIN into `ykman openpgp` / `keytocard`.                                                                                                                                                                          | Remember the rule: **`gpg` sign/decrypt wants User PIN (6+ digits); `ykman` and `keytocard` want Admin PIN (8+ digits).** Check remaining tries with `gpg --card-status` (`10 10 10`).                                                                                                                                                                                                                                                       |
| **`gpg: signing failed: Timeout`** / **`decryption failed: Timeout`**                             | The User PIN was accepted, and the YubiKey flashed its green LED waiting for a capacitive touch, but nobody touched the card within the timeout window.                                                                                                                                                                              | Re-run the command (`git commit`, `gpg --clearsign`, or `sops`) and physically touch the gold contact on the YubiKey as soon as the prompt returns or the LED blinks.                                                                                                                                                                                                                                                                        |
| **`gpg: selecting card failed: No such device`** on Linux                                         | Either (a) GnuPG's built-in `libusb` CCID driver and `pcscd` are fighting over the USB interface, or (b) a second `gpg-agent` / `scdaemon` in another `GNUPGHOME` already holds the card lock.                                                                                                                                       | (a) Ensure `disable-ccid` is in `~/.gnupg/scdaemon.conf` (`programs.gpg.scdaemonSettings.disable-ccid = true` in `home/dev.nix`). (b) Run `gpgconf --kill scdaemon` in the other `GNUPGHOME` to release the lock.                                                                                                                                                                                                                            |
| **`No smart card readers found`** / `No such device` over SSH on Slackware (`snail`)              | Slackware builds `scdaemon` without `libusb` (so `pcscd` is mandatory) and builds `pcsc-lite` with Polkit `allow_any=no`, denying non-seat SSH sessions. Or `slackpkg` reset `/etc/rc.d/rc.pcscd` to non-executable.                                                                                                                 | Install `/etc/polkit-1/rules.d/20-pcsc-plugdev.rules` granting `org.debian.pcsc-lite.access_pcsc` and `access_card` to group `plugdev`, and verify `chmod +x /etc/rc.d/rc.pcscd` + `/etc/rc.d/rc.pcscd start` (see [hosts.md](hosts.md)).                                                                                                                                                                                                    |
| **FIDO2 PIN reports `Blocked`** (`ykman fido info`)                                               | The FIDO2 applet PIN (completely separate from the OpenPGP applet PINs!) exceeded its 8 retry attempts. Note: our `pam_u2f` login (`~/.config/Yubico/u2f_keys`) uses classic U2F touch-only without a FIDO2 PIN, so `pam_u2f` keeps working even if FIDO2 PIN is blocked.                                                            | Unblocking the FIDO2 PIN requires `ykman fido reset` (must be run within 5 seconds of inserting the YubiKey). **WARNING**: `ykman fido reset` permanently destroys **all FIDO2 resident/discoverable credentials, all U2F registrations (including `~/.config/Yubico/u2f_keys` and web 2FA accounts), and the FIDO2 PIN**, requiring re-registration with `pamu2fcfg > ~/.config/Yubico/u2f_keys`. It does **not** touch the OpenPGP applet. |
| **`paperkey: unable to parse OpenPGP packets`**                                                   | Passed an ASCII-armored file (`~/gpg-master.asc` or `pub.asc`) directly to `paperkey --secret-key` or `paperkey --pubring`. `paperkey` only parses binary OpenPGP packets.                                                                                                                                                           | De-armor first: `gpg --dearmor < ~/gpg-master.asc \| paperkey` and `gpg --dearmor < ~/pub.asc > pub.gpg` before passing `--pubring pub.gpg`.                                                                                                                                                                                                                                                                                                 |
| **`sops updatekeys` says `already up to date`**, yet YubiKey cannot decrypt `secrets/common.yaml` | `sops updatekeys` compares the primary fingerprint string in `.sops.yaml` (`12D7...684C`) against `sops.pgp[].fp` in the file header. Because the primary fingerprint did not change when subkey `D1034A1D44262BC0` was added, SOPS skipped re-encryption and left the PKESK packet wrapped to the primary key (`3183124333AB684C`). | Use the hardened re-encryption recipe in [sops-break-glass.md](sops-break-glass.md) (private temp dir, `umask 077`, `diff` gate, atomic `mv`). Never redirect `sops -e` onto `secrets/common.yaml`, the shell truncates it first. Then verify `yq -r '.sops.pgp[0].enc' secrets/common.yaml \| gpg --list-packets` shows `keyid D1034A1D44262BC0`.                                                                                           |
