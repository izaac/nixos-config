# SSH Keys on Hardware

> **Last Updated**: 2026-11-22 **Hosts**: ninja, Mac, snail **Token**: YubiKey 5.7.1 (FIDO2 +
> OpenPGP + PIV) **Links**: [YubiKey Index](README.md) | [Git Signing](git-signing.md) |
> [Hosts](hosts.md)

---

## Decision

Use a **dedicated `ed25519-sk` resident credential in the FIDO2 applet** for SSH. Keep the GPG
identity separate and leave the GPG authentication subkey unused.

Reasons, in order of weight:

1. Physical presence is mandatory per authentication, enforced by the protocol rather than by a
   setting you can forget.
2. It needs nothing on the target machine beyond stock OpenSSH. No OpenSC, no PKCS#11 provider, no
   daemon, no config file.
3. The private key is generated inside the token, never exportable, and native resident credentials
   can be pulled onto any machine with `ssh-keygen -K`.
4. Blast radius stays separate: rotating an SSH key is one line in `authorized_keys`, whereas
   rotating a GPG subkey is a card ceremony plus a public key republication.

## The Three Options

|                                             | `ed25519-sk` (FIDO2)                   | PIV slot 9a (PKCS#11)                          | GPG auth subkey (agent)                  |
| ------------------------------------------- | -------------------------------------- | ---------------------------------------------- | ---------------------------------------- |
| Key material on token                       | yes, resident                          | yes                                            | yes, slot 3                              |
| Second factor                               | touch, plus PIN with `verify-required` | PIV PIN, touch only if policy set to `always`  | GPG user PIN, touch per UIF policy       |
| Needs on target machine                     | OpenSSH 8.2+ only                      | `opensc` + `pcscd` + `PKCS11Provider`          | gpg-agent + `SSH_AUTH_SOCK` redirect     |
| Portable to a machine you do not administer | yes                                    | usually not, needs packages                    | no                                       |
| Extra capability                            | none                                   | certificates, PKCS#11 for VPN/TLS, attestation | none                                     |
| Config failure mode                         | key simply not offered                 | silently falls back to another identity        | agent socket missing, auth fails quietly |

## Generating the Key

```bash
ssh-keygen -t ed25519-sk -O resident -O application=ssh:izaac \
  -C "izaac@yubikey-ssh" -f ~/.ssh/id_ed25519_sk
```

- `-O resident` stores the credential on the token so `ssh-keygen -K` can recover it elsewhere.
- `-O application=ssh:izaac` namespaces it away from browser WebAuthn credentials.
- Add `-O verify-required` for PIN plus touch per authentication. That equals PIV-with-touch-always
  in strength, at the cost of a PIN prompt per connection.

Authorise it where needed:

```bash
cat ~/.ssh/id_ed25519_sk.pub >> server:~/.ssh/authorized_keys   # or paste into GitHub
ssh-add -K ~/.ssh/id_ed25519_sk                                 # load from the card into the agent
```

On a different machine, the file is unnecessary:

```bash
ssh-keygen -K        # downloads the resident handle from the card into ~/.ssh/
```

## Wiring in `home/ssh.nix`

`IdentitiesOnly = "yes"` is already set for `*`, so a key is only offered where listed. Add the sk
key to the hosts that should use it:

```nix
github = {
  HostName = "github.com";
  User = "git";
  IdentityFile = ["~/.ssh/id_ed25519_sk"];
};
```

Leave the global `IdentityFile` alone so ordinary hosts keep using the software key until the sk key
is proven for them.

## PIV Alternative

Only worth it for the properties FIDO2 cannot give you: certificates, attestation, or a single
PKCS#11 identity for TLS and VPN.

```bash
ykman piv access change-pin          # factory 123456
ykman piv access change-puk          # factory 12345678
ykman piv access change-management-key --generate --protect
ykman piv keys generate 9a --algorithm eccp256 --touch-policy always
ykman piv certificates generate 9a --subject "CN=izaac ssh"
```

Then, per machine:

```bash
ssh-keygen -D /usr/lib64/opensc-pkcs11.so          # export the public key
ssh -o PKCS11Provider=/usr/lib64/opensc-pkcs11.so user@host
```

Provider paths differ: Debian `opensc-pkcs11.so`, Fedora `opensc-pkcs11.so` under `/usr/lib64`,
macOS `/Library/OpenSC/lib/opensc-pkcs11.so`. Needs OpenSC 0.23 or newer for current YubiKey
firmware.

## As Built (2026-11-22)

Generated on `ninja` with the resident variant:

```text
file         ~/.ssh/id_ed25519_sk      468 bytes, handle only
fingerprint  SHA256:C7HcBCb/Gh0D75fgVohBTXLGkjrpWxX295Gl98vDAJs
type         sk-ssh-ed25519@openssh.com
application  ssh:izaac
credential   resident, storage went from 100 free to 99
agent        ssh-add -K loads it from the card
wire         home/ssh.nix, host block "github", IdentityFile only that key
```

Gotchas learned in the process:

- **Resident creation asks for the FIDO2 PIN**, not the OpenPGP user or admin PIN. It is a third,
  separate secret, set with `ykman fido access change-pin`. A wrong entry costs one of its 8
  attempts, so do not guess; a blocked FIDO2 PIN is only cleared by a reset, which also drops U2F
  registrations.
- Creating the key does not need `-O verify-required`; adding it later means a PIN for every
  authentication.
- `gh ssh-key add` needs the `admin:public_key` scope, so adding the key is easier in the web UI.
- Verify the key with `ssh-keygen -lf`, not `-L`. `-L` is for certificates and reports "not a
  certificate" for a plain sk key.
- The `.pub` file is safe to share and can live on the offline drive; the handle file likewise,
  since it contains no secret, only the credential reference and application string.

## Migrating to Another Token

Nothing in this design is tied to YubiKey hardware except the on-card secrets, which are meant to be
replaceable.

| Artifact                         | Survives a token change | How                                                                              |
| -------------------------------- | ----------------------- | -------------------------------------------------------------------------------- |
| GPG identity                     | yes                     | primary lives on paper and the offline drive; mint new subkeys for the new token |
| `.sops.yaml`, keyservers, GitHub | yes                     | they reference the primary fingerprint, which does not change                    |
| `ed25519-sk` key                 | no, by design           | generate a new credential on the new token, swap one line in `authorized_keys`   |
| U2F/PAM registrations            | yes                     | re-register with `pamu2fcfg`, both tokens can coexist during the transition      |
| GPG subkeys on the old token     | no                      | revoke them, keep them in the key so old signatures still verify                 |

Tokens known to support resident `ed25519-sk`: YubiKey 5 series (fw 5.2.3+), Nitrokey 3 series (fw
1.8+). Solo 2 has an open report of resident sk-keys not working; verify current firmware before
relying on it.

## Troubleshooting

| Symptom                                                                                 | Cause                                                 | Fix                                                    |
| --------------------------------------------------------------------------------------- | ----------------------------------------------------- | ------------------------------------------------------ |
| `No FIDO device available`                                                              | token not seen, or OpenSSH built without FIDO support | replug, check `ssh -V`, verify `libfido2` is installed |
| `sk_enroll: ... does not support credprot, refusing to create unprotected resident key` | firmware cannot store resident credentials safely     | use a non-resident key, or update firmware             |
| `signing failed: Timeout`                                                               | touch never arrived                                   | rerun and touch when it blinks                         |
| Works locally, silent failure over `ssh host cmd`                                       | agent not forwarded and key on token only             | run with an agent, or use `ssh -A` deliberately        |
| Windows OpenSSH cannot use the key                                                      | Windows lacks FIDO2 support in OpenSSH                | use WSL or Git Bash                                    |
