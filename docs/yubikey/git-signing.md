# Git Commit & Tag Signing

> **Last Updated**: 2026-11-21 **Hardware**: YubiKey 5.7.1 (OpenPGP applet 3.4) **Hosts**: ninja,
> Mac, snail

---

## Documentation Links

- [YubiKey & OpenPGP Overview](README.md)
- [OpenPGP Applet Anatomy](gpg-applet.md)
- [Host Configuration (ninja, Mac, snail)](hosts.md)
- [SOPS Break-Glass Decryption](sops-break-glass.md)
- [Backup, Paperkey & Master Key Strip](backup-recovery.md)

---

## How Git Signing Works With Subkeys

Git is configured with the **primary key ID** (`0x3183124333AB684C` in `lib/user.nix`, imported by
`home/dev.nix`):

```nix
# lib/user.nix
gitKey = "0x3183124333AB684C";

# home/dev.nix
programs.git.signing = {
  key = userConfig.gitKey;
  signByDefault = true;
};
```

Equivalent raw `~/.gitconfig`:

```ini
[user]
    name = Izaac Zavaleta
    email = izaac.zavaleta@suse.com
    signingkey = 0x3183124333AB684C
[commit]
    gpgsign = true
[tag]
    gpgsign = true
```

Even though `user.signingkey` specifies the primary key ID (`3183124333AB684C`), GnuPG automatically
resolves the active signing-capable subkey (`54321CB1563EE61E`, Slot 1 on the YubiKey) and delegates
the signature computation to the smartcard. You do not need to change `user.signingkey` when
rotating signing subkeys under the same primary key.

---

## Daily User Experience

When you run `git commit` or `git tag -s`:

1. **First signature in a session (cold cache)**:
   - `pinentry` prompts for the **User PIN** (6+ digits).
   - `gpg-agent` caches the User PIN for `defaultCacheTtl = 3600` seconds (1 hour).
   - Once you enter the PIN, the YubiKey LED flashes waiting for physical touch.
   - Touch the gold contact on the YubiKey. The signature completes.
2. **Subsequent signatures within 15 seconds (touch policy `cached`)**:
   - Because Slot 1 (`sig`) uses touch policy `cached`, a burst of signatures within 15 seconds of a
     touch (such as `git rebase` or committing and immediately tagging) completes automatically with
     zero PIN prompts and zero extra touches.
3. **Subsequent signatures after 15 seconds (warm PIN cache, within 1 hour)**:
   - No PIN prompt appears.
   - The command pauses while the YubiKey LED flashes.
   - Touch the YubiKey once to complete the commit.
4. **If you forget to touch the YubiKey**:
   - After roughly 15 to 30 seconds, the card times out and Git fails with:

     ```text
     gpg: signing failed: Timeout
     error: gpg failed to sign the data
     fatal: failed to write commit object
     ```

   - Re-run `git commit` and touch the contact when it flashes.

---

## Verifying Signatures Locally

Inspect the signature on recent commits (for example, commit `285f746` "Add YubiKey as sops
break-glass recipient"):

```bash
git log --show-signature -n 3
```

Expected output:

```text
commit 285f746...
gpg: Signature made Sat 21 Nov 2026 ...
gpg:                using RSA key 78646A6070F607A2E3B7F21754321CB1563EE61E
gpg: Good signature from "Izaac Zavaleta <izaac@linux.com>" [ultimate]
gpg:                 aka "Izaac Zavaleta <izaac.zavaleta@suse.com>" [ultimate]
Primary key fingerprint: 12D7 7955 660C BE15 071B  7DB7 3183 1243 33AB 684C
     Subkey fingerprint: 7864 6A60 70F6 07A2 E3B7  F217 5432 1CB1 563E E61E
Author: Izaac Zavaleta <izaac.zavaleta@suse.com>
Date:   Sat Nov 21 2026 ...

    Add YubiKey as sops break-glass recipient
```

Notice the two lines:

- **`using RSA key ...54321CB1563EE61E`**: confirms the signature was produced by Slot 1 on the
  YubiKey, not by the primary key.
- **`Primary key fingerprint: 12D7 7955 ... 33AB 684C`**: confirms the subkey is cryptographically
  bound to the primary identity.

To verify a signed tag:

```bash
git tag -v <tag-name>
```

---

## How Third Parties Verify Your Commits

A verifier (GitHub, GitLab, or a colleague running `git log --show-signature`) needs your **updated
public key containing the new subkey binding signatures** (`54321CB1563EE61E`, `D1034A1D44262BC0`,
`E5C447A6591778E2`).

If a verifier only has an older copy of your public key (from before `2026-11-21`, when the card
subkeys were minted), `gpg --verify` reports:

```text
gpg: Signature made ...
gpg:                using RSA key 78646A6070F607A2E3B7F21754321CB1563EE61E
gpg: Can't check signature: No public key
```

---

## Publishing the Public Key

Whenever subkeys are added, rotated, or have their expiration dates extended, the armored public key
must be re-exported and uploaded everywhere verifiers look.

### 1. Export the Full Public Key (Primary + Subkeys)

```bash
gpg --armor --export 12D77955660CBE15071B7DB73183124333AB684C > pub.asc
```

Verify that the exported block includes the three `ssb`/`sub` packets before uploading:

```bash
gpg --show-keys --keyid-format=long pub.asc
```

Expected output:

```text
pub   rsa4096/3183124333AB684C 2024-03-12 [SC] [expires: 2029-02-06]
      12D77955660CBE15071B7DB73183124333AB684C
uid                            Izaac Zavaleta <izaac@linux.com>
uid                            Izaac Zavaleta <izaac.zavaleta@suse.com>
sub   rsa4096/E5C447A6591778E2 2026-11-21 [A] [expires: 2028-11-20]
sub   rsa4096/54321CB1563EE61E 2026-11-21 [S] [expires: 2028-11-20]
sub   rsa4096/D1034A1D44262BC0 2026-11-21 [E] [expires: 2028-11-20]
```

### 2. Upload to `keys.openpgp.org` (Done)

`keys.openpgp.org` strips UID packets unless each email address is verified via a confirmation link.

```bash
gpg --keyserver hkps://keys.openpgp.org --send-keys 12D77955660CBE15071B7DB73183124333AB684C
```

Or upload directly via the API and request the verification email:

```bash
curl -T pub.asc https://keys.openpgp.org
```

Once uploaded, click the verification link sent to `izaac@linux.com` and `izaac.zavaleta@suse.com`
so lookups by email return the key with UIDs attached.

### 3. Update GitHub GPG Keys (Done)

GitHub does **not** automatically poll public keyservers when a key adds new subkeys.

1. Go to **GitHub Settings -> SSH and GPG keys**.
2. Delete the old entry for key ID `3183124333AB684C` (which lacked the `2026-11-21` subkeys).
3. Click **New GPG key** and paste the contents of `pub.asc`.
4. Confirm that subkey `54321CB1563EE61E` appears under the key entry in GitHub Settings, and that
   commit `285f746` displays the green **Verified** badge.

### 4. Pending Action: Refresh `keyserver.ubuntu.com`

As of `2026-11-21`, `keyserver.ubuntu.com` still serves the older copy of
`12D77955660CBE15071B7DB73183124333AB684C` without the three card subkeys. Push the updated public
key to Ubuntu's HKPS keyserver so tools defaulting to `hkps://keyserver.ubuntu.com` can verify
commits and encrypt to `D1034A1D44262BC0`:

```bash
gpg --keyserver hkps://keyserver.ubuntu.com --send-keys 12D77955660CBE15071B7DB73183124333AB684C
```

Verify propagation after sending:

```bash
gpg --batch --keyserver hkps://keyserver.ubuntu.com --search-keys 12D77955660CBE15071B7DB73183124333AB684C
```

---

## Machines Without the YubiKey

Never copy `~/.gnupg` or export software secret keys onto headless servers (`plex`), remote VMs, or
secondary laptops where the YubiKey is not plugged in.

If you need to create commits on a machine where the YubiKey is not present, choose one of these two
options:

### Option A: Disable GPG Signing Per-Repo or Per-Command

For a single commit without the card:

```bash
git commit --no-gpg-sign -m "Update configuration"
```

For an entire repository on a headless host (such as `plex`):

```bash
git config --local commit.gpgsign false
git config --local tag.gpgsign false
```

### Option B: Use SSH Commit Signing on Cardless Machines

If you still want verified commits from a machine that holds its own SSH key (such as
`~/.ssh/id_ed25519` registered as a Signing Key on GitHub) without carrying the YubiKey:

```bash
git config --local gpg.format ssh
git config --local user.signingkey ~/.ssh/id_ed25519.pub
git config --local commit.gpgsign true
```

This keeps the YubiKey OpenPGP subkeys strictly hardware-bound while allowing host-specific SSH
signing where appropriate.
