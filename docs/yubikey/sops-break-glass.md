# SOPS Break-Glass Decryption with YubiKey

> **Last Updated**: 2026-11-21 **Hardware**: YubiKey 5.7.1 (OpenPGP applet 3.4) **Hosts**: ninja,
> Mac, snail

---

## Documentation Links

- [YubiKey & OpenPGP Overview](README.md)
- [OpenPGP Applet Anatomy](gpg-applet.md)
- [Host Configuration (ninja, Mac, snail)](hosts.md)
- [Git Commit & Tag Signing](git-signing.md)
- [Backup, Paperkey & Master Key Strip](backup-recovery.md)
- [Secret Management with sops-nix](../secrets.md)

---

## Why the YubiKey Is a SOPS Recipient

NixOS hosts using `sops-nix` must be able to reboot unattended without a human standing by to type a
PIN or touch a YubiKey. At the same time, relying solely on machine-local `age` keys
(`~/.config/sops/age/keys.txt` and `/etc/ssh/ssh_host_ed25519_key`) creates a catastrophic single
point of failure: if the workstations (`ninja` and `Mac`) are destroyed, stolen, or suffer
simultaneous drive failures, the encrypted secrets in `secrets/common.yaml` become permanently
unrecoverable.

Adding the YubiKey OpenPGP key (`12D77955660CBE15071B7DB73183124333AB684C`, encrypting to Slot 2
subkey `D1034A1D44262BC0`) as an additional SOPS recipient gives the best of both worlds:

1. **Boot stays silent and unattended**: `modules/core/sops.nix` sets
   `sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ]` plus
   `sops.age.keyFile = "${home}/.config/sops/age/keys.txt"`. At boot or `just build`, `sops-nix`
   unwraps the data key with the host `age` key immediately. The YubiKey does not need to be plugged
   in.
2. **Physical break-glass recovery**: Every secret file's data encryption key (DEK) is also wrapped
   to the YubiKey's RSA-4096 encryption subkey (`D1034A1D44262BC0`). On any clean machine with
   `git`, `sops`, `gpg`, and the physical YubiKey, you can decrypt and rekey every secret in the
   repository.

---

## SOPS `key_groups` OR vs AND Semantics

In `.sops.yaml`, the structure of `key_groups` determines whether SOPS uses **boolean OR** (any
single key can decrypt) or **Shamir Secret Sharing boolean AND** (multiple keys required
simultaneously).

- **One `-` item under `key_groups` containing both `age:` and `pgp:` lists = Boolean OR.** SOPS
  encrypts the file's data key independently for every listed `age` and `pgp` recipient. Any single
  recipient (`*host_ninja` at boot, `*user_ninja` or `*user_mac` during daily edits, or `*yubikey`
  during break-glass recovery) can unwrap the data key alone.
- **Two separate `-` items under `key_groups` = Shamir Secret Sharing AND (Threshold = 2).** If you
  accidentally write `- age: ...` followed by `- pgp: ...` as a second list element, SOPS splits the
  data key into Shamir shares requiring **both** an `age` key **and** the YubiKey physical touch on
  every boot. That breaks unattended NixOS activation.

### Actual `.sops.yaml` Configuration

```yaml
keys:
  # User keys - for editing secrets from each workstation. Derived from each
  # machine's user SSH key via `ssh-to-age < ~/.ssh/id_ed25519.pub`.
  - &user_ninja age16ac3y79srzrcjapnqr08ddfqtjxuncz94qs3k7j62r8lyfr88yzsl2u6el
  - &user_mac age1c2tvqnc3gu3vhgvyfa8yqhl5jts2mpmzf442cqmpqesacdpr69sq9dzdqd
  # Host keys - for boot-time decryption via sops-nix `sshKeyPaths`. Derived
  # from /etc/ssh/ssh_host_ed25519_key.pub.
  - &host_ninja age1cjc00x0g5mhejndsh3ljz09ukkl38kutd692aatd3qw0jrmxx3sq4tk5av
  # YubiKey GPG master key (OpenPGP applet, breakout/panic card).
  # Break-glass recipient: any one of the age recipients OR this key can
  # decrypt, because all of them sit in the same key_groups entry.
  - &yubikey 12D77955660CBE15071B7DB73183124333AB684C
creation_rules:
  # Common secrets - readable by every host and every editor.
  - path_regex: secrets/common\.yaml$
    key_groups:
      - age:
          - *user_ninja
          - *user_mac
          - *host_ninja
        pgp:
          - *yubikey
  # Per-host slots - pre-wired so adding host-specific secrets is a one-step
  # `sops secrets/<host>.yaml` away. Same recipients today; tighten when each
  # host gets its own host key.
  - path_regex: secrets/ninja\.yaml$
    key_groups:
      - age:
          - *user_ninja
          - *user_mac
          - *host_ninja
        pgp:
          - *yubikey
  - path_regex: secrets/plex\.yaml$
    key_groups:
      - age:
          - *user_ninja
          - *user_mac
          - *host_ninja
        pgp:
          - *yubikey
```

---

## Operational Gotcha: Why `sops updatekeys` Skips Subkey Rotation

When `.sops.yaml` lists the primary fingerprint `12D77955660CBE15071B7DB73183124333AB684C` under
`pgp:`, SOPS stores that primary fingerprint string in the `sops.pgp[].fp` metadata array of
`secrets/common.yaml`, while delegating the actual OpenPGP encryption packet (`PKESK`, Public-Key
Encrypted Session Key) to `gpg --encrypt -r 12D77955660CBE15071B7DB73183124333AB684C`.

### What Went Wrong First

If `secrets/common.yaml` was initially encrypted **before** the encryption subkey
(`D1034A1D44262BC0`) was minted (or in a keyring that only had the primary key `3183124333AB684C`
with `escESCA` capabilities), `gpg` wrapped the SOPS data key directly to the **primary key ID
`3183124333AB684C`**.

After minting the card subkey `D1034A1D44262BC0`, running:

```bash
sops updatekeys secrets/common.yaml
```

prints:

```text
2026/11/21 ... Syncing keys for file secrets/common.yaml
2026/11/21 ... File secrets/common.yaml already up to date
```

Because `sops updatekeys` only diffs the recipient fingerprint string
(`12D77955660CBE15071B7DB73183124333AB684C`) in `.sops.yaml` against `sops.pgp[].fp` in
`secrets/common.yaml`, it sees no change and does **not** re-run `gpg --encrypt`. As a result, the
PGP ciphertext inside `secrets/common.yaml` remains wrapped to the primary key (`3183124333AB684C`)
instead of the YubiKey's Slot 2 encryption subkey (`D1034A1D44262BC0`). Once the primary key is
stripped from disk, the YubiKey cannot decrypt that packet.

### The Fix: Force Re-Encryption and Verify the PKESK Key ID

To force SOPS to generate a fresh data key and re-invoke `gpg --encrypt` against the current keyring
(which selects the newest encryption subkey `D1034A1D44262BC0`):

```bash
set -euo pipefail
umask 077
tmp="$(mktemp -d)"
trap 'shred -u "$tmp/plain.yaml" 2>/dev/null || true; rm -rf "$tmp"' EXIT

sops -d secrets/common.yaml > "$tmp/plain.yaml"
sops -e --filename-override secrets/common.yaml "$tmp/plain.yaml" > "$tmp/new.yaml"

# Prove the re-encrypted file still decrypts to the identical plaintext
sops -d "$tmp/new.yaml" | diff - "$tmp/plain.yaml"

# Only now replace the committed file
mv "$tmp/new.yaml" secrets/common.yaml
```

Never redirect `sops -e` straight onto `secrets/common.yaml`. The shell truncates the target before
`sops` reads it, so a failure at that moment leaves you with an empty file. The `diff` step is the
gate, and `git` holds the previous ciphertext if you need to restore it
(`git checkout -- secrets/common.yaml`).

### Verify That `secrets/common.yaml` Is Wrapped to Subkey `D1034A1D44262BC0`

Extract the armored PGP packet from `secrets/common.yaml` and inspect its OpenPGP packet header with
`gpg --list-packets`:

```bash
yq -r '.sops.pgp[0].enc' secrets/common.yaml | gpg --list-packets
```

Expected output:

```text
# off=0 ctb=85 tag=1 hlen=3 plen=524
:pubkey enc packet: version 3, algo 1, keyid D1034A1D44262BC0
        data: [4096 bits]
# off=527 ctb=d2 tag=18 hlen=2 plen=130 new-ctb
:encrypted data packet:
        length: 130
        mdc_method: 2
```

The line `keyid D1034A1D44262BC0` proves the SOPS data key is wrapped to YubiKey Slot 2
(`D1034A1D44262BC0`), NOT the primary key (`3183124333AB684C`).

---

## Testing Break-Glass Decryption (Simulating Total Age Key Loss)

To prove the YubiKey can decrypt `secrets/common.yaml` on its own without any `age` key present:

```bash
# Force sops to ignore ~/.config/sops/age/keys.txt by pointing SOPS_AGE_KEY_FILE to /dev/null
SOPS_AGE_KEY_FILE=/dev/null sops -d secrets/common.yaml
```

What happens:

1. SOPS fails to find a matching `age` identity and falls back to the `sops.pgp` entry.
2. SOPS invokes `gpg --decrypt` on the armored PGP block (`keyid D1034A1D44262BC0`).
3. `pinentry` prompts for the YubiKey **User PIN** (if not cached).
4. The YubiKey LED flashes (Slot 2 touch policy is `on`, so **every** decryption requires a fresh
   physical touch).
5. Touch the YubiKey. The decrypted YAML prints to stdout.

---

## Disaster Recovery Matrix

> **Plain Rule**: The `paperkey` printout and `~/gpg-master.asc` hold the **primary certification
> key (`33AB684C`) only**. They do **not** contain the encryption subkey (`D1034A1D44262BC0`).
> Therefore, **paper restores your OpenPGP identity, never SOPS ciphertext.**

| Disaster Scenario                                                                     | Surviving Assets                                                                                            | Impact on Boot & SOPS Secrets                                                                                                     | Impact on GPG Identity                                                                                         | Recovery Procedure                                                                                                                                                                                                                                                  |
| :------------------------------------------------------------------------------------ | :---------------------------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **1. `ninja` lost or SSD dies** (`Mac` and YubiKey survive)                           | `Mac` (`*user_mac`), YubiKey (`*yubikey`), offline master backup                                            | **Zero data loss.** Both `Mac` (`age`) and YubiKey (`pgp`) can decrypt `secrets/common.yaml`.                                     | **Intact.** Card still holds subkeys; offline backup holds primary.                                            | Rebuild `ninja`, generate new host/user SSH->`age` keys, update `.sops.yaml` using `Mac` or YubiKey, run `sops updatekeys`.                                                                                                                                         |
| **2. Both `ninja` and `Mac` lost** (YubiKey + offline master survive)                 | YubiKey (`*yubikey`), GitHub repo clone, offline master backup                                              | **Zero data loss.** YubiKey Slot 2 (`D1034A1D44262BC0`) decrypts `secrets/common.yaml` via `SOPS_AGE_KEY_FILE=/dev/null sops -d`. | **Intact.** Card holds subkeys; offline backup holds primary.                                                  | Clone repo on new machine, import `pub.asc`, run `gpg --card-status`, decrypt secrets with YubiKey, add new machine `age` keys to `.sops.yaml`, re-encrypt.                                                                                                         |
| **3. YubiKey lost, stolen, or broken** (`ninja` or `Mac` + offline master survive)    | `ninja` (`*user_ninja`, `*host_ninja`) and/or `Mac` (`*user_mac`), offline master backup (`paperkey` / USB) | **Zero data loss.** Workstations decrypt `secrets/common.yaml` via their `age` keys.                                              | **Recoverable.** Primary key is safe on paper/USB. Old card subkeys are compromised if card + PIN were stolen. | Import `~/gpg-master.asc` (or `paperkey` restore), revoke compromised subkeys (`563EE61E`, `44262BC0`, `591778E2`), mint 3 new subkeys onto replacement YubiKey, publish new `pub.asc`, and force-re-encrypt `secrets/common.yaml` (`sops -e --filename-override`). |
| **4. Both workstations AND YubiKey lost** (only `paperkey` / offline master survives) | Offline master backup (`paperkey` / `gpg-master.asc`) + GitHub repo clone                                   | **SOPS ciphertext UNRECOVERABLE.** Neither the `age` private keys nor subkey `D1034A1D44262BC0` exist anywhere.                   | **Identity recoverable.** Primary key (`33AB684C`) is restored from paper/USB.                                 | Restore primary key from `paperkey`, revoke old subkeys, mint new subkeys on a new YubiKey, and manually recreate `secrets/common.yaml` from upstream cloud/API consoles.                                                                                           |
