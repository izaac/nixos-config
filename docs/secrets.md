# Secret Management with sops-nix

This project uses [sops-nix](https://github.com/Mic92/sops-nix) to keep secrets
(API tokens, SSH host data, passwords) encrypted in the git repository and
decrypted **only on machines that hold a matching private key**. Encrypted
files are safe to commit and push to GitHub; the cleartext never persists to
disk. It only lives in `/run/secrets/` (tmpfs) at runtime.

---

## Architecture at a glance

```text
                              ┌──────────────────────────┐
                              │     .sops.yaml           │
                              │  (key aliases + rules)   │
                              └────────────┬─────────────┘
                                           │ tells sops which
                                           │ recipients each file
                                           │ should be encrypted for
                                           ▼
       ┌───────────────────────────────────────────────────────────┐
       │   secrets/common.yaml                                     │
       │   - sshHost, geminiProject, cloudCodeProject              │
       │   - encrypted to: user_ninja, user_mac, host_shared       │
       └───────────────────────────────────────────────────────────┘
       ┌───────────────────────────────────────────────────────────┐
       │   secrets/ninja.yaml   (per-host slot, create on demand)  │
       │   secrets/windy.yaml   (per-host slot, create on demand)  │
       └───────────────────────────────────────────────────────────┘

                   Decryption requires a PRIVATE key matching
                   one of the recipients listed in the file header.

  ┌─────────────────────────┐      ┌─────────────────────────┐
  │   Boot path (NixOS)     │      │   Editor path (any)     │
  │                         │      │                         │
  │   root reads            │      │   user reads            │
  │   /etc/ssh/             │      │   ~/.config/sops/age/   │
  │     ssh_host_ed25519_   │      │     keys.txt            │
  │     key  (host SSH)     │      │   (user age key,        │
  │       │                 │      │    derived from         │
  │       ▼                 │      │    ~/.ssh/id_ed25519)   │
  │   sops-nix derives      │      │       │                 │
  │   age private key       │      │       ▼                 │
  │       │                 │      │   sops CLI uses it      │
  │       ▼                 │      │   to decrypt for edit   │
  │   decrypts secret →     │      │                         │
  │   /run/secrets/*        │      │                         │
  └─────────────────────────┘      └─────────────────────────┘
```

---

## Recipients (private keys ↔ machines)

`.sops.yaml` defines three named recipients via YAML aliases:

| Alias          | What it is                                               | Lives on                                                   | Used for                               |
| -------------- | -------------------------------------------------------- | ---------------------------------------------------------- | -------------------------------------- |
| `&user_ninja`  | Age key derived from ninja user SSH key                  | `~/.config/sops/age/keys.txt`                              | Editing secrets from ninja             |
| `&user_mac`    | Age key derived from Mac user SSH key                    | `~/.config/sops/age/keys.txt` (Linux path) + macOS symlink | Editing secrets from Mac               |
| `&host_shared` | Age key derived from `/etc/ssh/ssh_host_ed25519_key.pub` | ninja + windy (shared today)                               | Boot-time decryption via `sshKeyPaths` |

**Property to preserve:** every secrets file MUST list at least one editor
recipient (e.g. `*user_mac`) so a human can always rekey. Without that you'd
need a host to be online to recover, which defeats the point.

---

## Files

| Path                    | Purpose                                                           |
| ----------------------- | ----------------------------------------------------------------- |
| `.sops.yaml`            | Master config: recipient aliases + `path_regex` → recipient rules |
| `secrets/common.yaml`   | Shared secrets, readable by every host                            |
| `secrets/ninja.yaml`    | (Optional) ninja-only secrets, create when needed                 |
| `secrets/windy.yaml`    | (Optional) windy-only secrets, create when needed                 |
| `modules/core/sops.nix` | sops-nix integration; declares which secrets to expose at runtime |

The encrypted files commit as gibberish; only the YAML structure leaks.
The cleartext only ever exists in:

- **An editor session** (`sops secrets/...` runs `$EDITOR` on a tmpfile)
- **`/run/secrets/`** on each host at runtime (tmpfs, root-owned by default)

---

## Boot flow: how a NixOS host decrypts at activation

```text
   1.  systemd boots
       │
       ▼
   2.  sops-nix activation script runs as root
       │
       ▼
   3.  Reads modules/core/sops.nix
       sops.defaultSopsFile     = secrets/common.yaml
       sops.age.sshKeyPaths     = [ "/etc/ssh/ssh_host_ed25519_key" ]
       sops.age.keyFile         = "/home/izaac/.config/sops/age/keys.txt"
       │
       ▼
   4.  For each declared sops.secrets.<name>:
       ├──> Open secrets/common.yaml
       ├──> Read encrypted-data-key header (one entry per recipient)
       ├──> Try each available private key:
       │    ├── derived from /etc/ssh/ssh_host_ed25519_key (preferred)
       │    └── fallback: ~/.config/sops/age/keys.txt
       │
       ├──> One match → decrypt data key → decrypt the secret payload
       │
       └──> Write cleartext to /run/secrets/<name>
            (tmpfs, mode 0400, owner from sops.secrets.<name>.owner)
       │
       ▼
   5.  Services that reference config.sops.secrets.<name>.path
       see the cleartext file appear before they start.
```

**Why `sshKeyPaths` matters:** without it, the activation step depends on
`~/.config/sops/age/keys.txt` existing in the user's home directory. That file
isn't guaranteed to be present before activation finishes (esp. on a fresh
install). With `sshKeyPaths`, sops-nix uses `/etc/ssh/ssh_host_ed25519_key`
(generated by sshd on first boot and always present on a NixOS host) and
derives the age private key on the fly. Decryption becomes a function of
system state only, with no user-space prerequisite.

If neither key path can decrypt, activation **fails the rebuild** with a
clear error. Better to fail loud than boot with missing secrets.

---

## Editor flow: when you run `sops secrets/common.yaml`

```text
   1.  sops CLI starts
       │
       ▼
   2.  Reads .sops.yaml → finds matching creation_rule by path_regex
       │
       ▼
   3.  Reads secrets/common.yaml header → list of recipient encrypted data keys
       │
       ▼
   4.  Walks the age key search path:
       Linux:  ~/.config/sops/age/keys.txt
       macOS:  ~/Library/Application Support/sops/age/keys.txt
               (this project symlinks → ~/.config/sops/age/keys.txt)
       │
       ▼
   5.  First private key that matches a recipient → decrypts data key
       │
       ▼
   6.  Decrypted YAML opens in $EDITOR
       │
       ▼
   7.  On save, sops re-encrypts the data key for ALL recipients
       listed in the matching creation_rule of .sops.yaml
```

> **macOS gotcha:** sops on macOS looks in `~/Library/Application Support/sops/age/keys.txt`,
> not the Linux `~/.config` path. This repo's setup symlinks the macOS path
> to the Linux path so the same key serves both. If decryption suddenly fails
> on Mac with "no identity matched any of the recipients", check the symlink.

---

## Common operations

### Edit common secrets

```bash
sops secrets/common.yaml
```

### Add a host-specific secret

```bash
sops secrets/ninja.yaml      # creates file on first save
                              # automatically encrypted for the recipients
                              # listed in the matching .sops.yaml rule
```

### Add a new secret to the Nix module

In `modules/core/sops.nix`:

```nix
sops.secrets.my_new_thing = {
  sopsFile = ../../secrets/common.yaml;  # or secrets/ninja.yaml etc.
  owner = userConfig.username;            # who can read /run/secrets/my_new_thing
  # Optional:
  # group = "users";
  # mode  = "0440";
};
```

Reference it from a service:

```nix
systemd.user.services.example = {
  script = ''
    TOKEN=$(cat ${config.sops.secrets.my_new_thing.path})
    do-stuff --token "$TOKEN"
  '';
};
```

### Add a new host or user as a recipient

1. Get the age recipient:

   ```bash
   # For a USER key:
   ssh-to-age < ~/.ssh/id_ed25519.pub

   # For a HOST key (run on the new host):
   cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age
   ```

2. Add it to `.sops.yaml` as a new alias and include in the relevant
   `creation_rules`.
3. Re-encrypt every affected file (run from a machine that can already decrypt):

   ```bash
   sops updatekeys secrets/common.yaml
   sops updatekeys secrets/ninja.yaml   # only if it exists
   ```

4. Commit. The cleartext didn't change; only the encrypted data-key
   header for the new recipient.

### Initial setup on a new editor machine

```bash
# 1. Derive the user age private key from your SSH private key
mkdir -p ~/.config/sops/age
nix shell nixpkgs#ssh-to-age -c bash -c \
  'ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt'
chmod 600 ~/.config/sops/age/keys.txt

# 2. macOS only: symlink to the macOS-native sops path
mkdir -p ~/Library/Application\ Support/sops/age
ln -sf ~/.config/sops/age/keys.txt \
  ~/Library/Application\ Support/sops/age/keys.txt

# 3. Verify
sops -d secrets/common.yaml | head -3
```

---

## Per-host secret layout

`secrets/common.yaml` is for things every host needs (user-scoped API tokens,
shared connection details). Host-specific data goes in `secrets/<host>.yaml`
so that compromising one host doesn't expose another host's secrets.

The `.sops.yaml` rules are **pre-wired** for `secrets/ninja.yaml` and
`secrets/windy.yaml`. You don't need to edit `.sops.yaml` to start using
them. Just `sops secrets/ninja.yaml` and the matching rule picks up
automatically.

Today both per-host rules list the same recipients (ninja + windy share a
host SSH key). When windy gets its own host key, split `&host_shared` into
`&host_ninja` and `&host_windy` and narrow the per-host rules accordingly.

---

## Troubleshooting

| Symptom                                                | Likely cause                                                  | Fix                                                                                                     |
| ------------------------------------------------------ | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| `no identity matched any of the recipients`            | Your private key isn't in `.sops.yaml`, or sops can't find it | Verify `age-keygen -y ~/.config/sops/age/keys.txt` is listed as a recipient                             |
| `no identity matched ...` on Mac only                  | Missing macOS symlink                                         | `ln -sf ~/.config/sops/age/keys.txt ~/Library/Application\ Support/sops/age/keys.txt`                   |
| sops-nix activation fails at rebuild                   | Host SSH key isn't a recipient                                | Get `age` from `cat /etc/ssh/ssh_host_ed25519_key.pub \| ssh-to-age`, add to `.sops.yaml`, `updatekeys` |
| Edited a secret on host A, host B still sees old value | Host B hasn't rebuilt                                         | `just build` on host B; `/run/secrets/` regenerates at activation                                       |
| Added new recipient but Mac still can't decrypt        | Forgot `sops updatekeys`                                      | Run `sops updatekeys secrets/<file>.yaml` from a machine that already decrypts                          |
| Moved a file between rules and decryption broke        | File header still encrypted for old rule's recipients         | `sops updatekeys` re-syncs the header to match the matching rule                                        |

---

## Security model: what protects what

- **At rest (the git repo + GitHub):** The secret payload is AES-GCM
  encrypted under a per-file data key. The data key is wrapped under each
  recipient's age public key. A stranger forking the repo sees only ciphertext.
- **In transit (push/pull):** Same as above. The encrypted file is what
  moves over the wire.
- **At runtime:** `/run/secrets/` lives on tmpfs (RAM only), mode 0400 by
  default. Reboot wipes it. File ownership is whatever each
  `sops.secrets.<name>.owner` says.
- **Compromise blast radius:** If a host's SSH host key leaks, every secret
  encrypted to that host's recipient is exposed. Per-host secret files
  (`secrets/<host>.yaml`) limit this: only that host's per-file secrets
  leak, not the shared `common.yaml`. Common secrets remain at risk by
  design because every host can read them, which is what "common" means.
- **Key rotation:** Changing an SSH key changes the derived age key.
  Workflow: add new recipient → `sops updatekeys` everywhere → remove old
  recipient from `.sops.yaml` → `sops updatekeys` again.
