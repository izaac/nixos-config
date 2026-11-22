# Host Configuration & Smartcard Access

> **Last Updated**: 2026-11-21 **Hardware**: YubiKey 5.7.1 (OpenPGP applet 3.4) **Hosts**: ninja,
> Mac, snail

---

## Documentation Links

- [YubiKey & OpenPGP Overview](README.md)
- [OpenPGP Applet Anatomy](gpg-applet.md)
- [Git Commit & Tag Signing](git-signing.md)
- [SOPS Break-Glass Decryption](sops-break-glass.md)
- [Backup, Paperkey & Master Key Strip](backup-recovery.md)
- [Host Configuration (Mac)](../mac.md)

---

## Host Matrix

| Host                   | OS / Platform                         | Role                                   | SOPS Enabled                                                                    | Card Needed at Boot?                                  | Signing & Smartcard Path                                                                                                   |
| :--------------------- | :------------------------------------ | :------------------------------------- | :------------------------------------------------------------------------------ | :---------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------- |
| **ninja**              | NixOS 26.05 (`x86_64-linux`)          | Workstation (`workstation.nix`)        | **Yes** (`modules/core/sops.nix`)                                               | **No** (decrypts via `/etc/ssh/ssh_host_ed25519_key`) | `services.pcscd` + `disable-ccid = true` (`home/dev.nix`), `pinentry-auto` (`curses` in tmux/TTY, `gnome3` in Wayland)     |
| **Mac**                | macOS (`aarch64-darwin`, nix-darwin)  | Laptop (`hosts/Mac/configuration.nix`) | **No** (no sops-nix module; uses `sops` CLI with `~/.config/sops/age/keys.txt`) | **No**                                                | Homebrew cask `gpg-suite-no-mail`, `pinentry-mac` GUI dialog, macOS native CryptoTokenKit/PC/SC (no `disable-ccid` needed) |
| **snail**              | Slackware 15.0-current (`gpg 2.5.24`) | External Linux host                    | **No**                                                                          | **No**                                                | `rc.pcscd` (`chmod +x`), Polkit rule `/etc/polkit-1/rules.d/20-pcsc-plugdev.rules` for `plugdev`, `pinentry-tty`           |
| **plex**               | NixOS 26.05 (`x86_64-linux`)          | Headless server (`server.nix`)         | **No** (`sops.enable = false`, `yubikey.enable = false`)                        | **No**                                                | No card attached (`commit.gpgsign = false` if committing locally)                                                          |
| **canoe / canoe-niri** | NixOS Live ISO (`hosts/canoe/`)       | Installer / recovery ISOs              | **No** (not deployed hosts)                                                     | **No**                                                | Ephemeral recovery media only                                                                                              |

---

## Universal Rules Across All Hosts

### 1. Only One `gpg-agent` Homedir Can Hold the Card at a Time

When `gpg` talks to the YubiKey, `gpg-agent` spawns `scdaemon`, which acquires an exclusive lock on
the OpenPGP CCID interface.

- If your primary `~/.gnupg` agent has an active `scdaemon` holding the card and you run a test
  command inside a temporary `GNUPGHOME=/tmp/test-gpg`, the second `scdaemon` will fail with
  `No such device` or `Card error`.
- Always release the card from the active agent before switching `GNUPGHOME`:

  ```bash
  gpgconf --kill scdaemon
  # or stop the entire agent in the old homedir:
  gpgconf --kill gpg-agent
  ```

### 2. Requirements for Any Fresh or Scratch `GNUPGHOME`

Whenever you create an isolated `GNUPGHOME` (for example, testing `paperkey` restore or break-glass
SOPS decryption in `/tmp/opencode/gpg-test`), GnuPG ignores `~/.gnupg/`. You must populate two files
inside the scratch directory before running `gpg`:

```bash
export GNUPGHOME=/tmp/opencode/gpg-test
mkdir -p "$GNUPGHOME" && chmod 700 "$GNUPGHOME"

# 1. Tell gpg-agent which pinentry binary to execute
cat > "$GNUPGHOME/gpg-agent.conf" <<EOF
pinentry-program $(command -v pinentry-curses || command -v pinentry-tty || command -v pinentry)
EOF

# 2. On Linux hosts running pcscd, disable internal CCID so scdaemon uses PC/SC
cat > "$GNUPGHOME/scdaemon.conf" <<EOF
disable-ccid
EOF
```

### 3. Public Key Plus `gpg --card-status` Creates the Stubs

The YubiKey holds the raw RSA private keys and key fingerprints, **not** the full OpenPGP public key
packet structure or UID self-signatures. On any new machine, you must:

1. Import the public key (`pub.asc` or from `keys.openpgp.org` / GitHub).
2. Plug in the YubiKey and run `gpg --card-status`.

Seeing the card serial and matching subkey fingerprints causes `gpg` to automatically generate the
`ssb>` secret key stubs in that machine's local keyring. Never copy `~/.gnupg` between machines.

---

## Adding a New Machine: Decision Checklist

Work top to bottom. Steps 1 to 7 make signing work, step 8 makes the machine part of sops.

1. **Pick the class** and follow the matching section below: NixOS (`ninja`), macOS (`Mac`),
   Slackware (`snail`). Nothing about the card is host specific, only where `pcscd` and pinentry
   live.
2. **Install the stack**: GnuPG plus a smartcard daemon. Linux needs `pcscd`; NixOS gets it from
   `services.pcscd.enable = true`, Slackware from the packaged `pcsc-lite`, macOS from GPG Suite.
3. **Import the public key** (never the secret):
   `gpg --keyserver hkps://keys.openpgp.org --recv-keys 12D77955660CBE15071B7DB73183124333AB684C`.
   Confirm `gpg --list-keys 12D7... | grep -c '^sub'` prints `3`.
4. **Insert the card** and run `gpg --card-status`. You want `Reader`, plus Signature, Encryption
   and Authentication fingerprints. If it fails, go to
   [Universal Rules](#universal-rules-across-all-hosts) before touching config.
5. **Configure pinentry** for the session type: `pinentry-auto` on NixOS, `pinentry-mac` on macOS,
   `pinentry-tty` on Slackware. Export `GPG_TTY=$(tty)` in interactive shells.
6. **Configure git**: `user.signingkey 0x3183124333AB684C`, `commit.gpgsign true`,
   `tag.gpgsign true`, real `user.name` and `user.email`.
7. **Prove it**: `echo t | gpg --clearsign -u 0x3183124333AB684C > /dev/null`. PIN, then touch. Then
   commit once and check `git log --show-signature -1`.
8. **Only if this machine also decrypts sops at boot**: it needs its own age recipient. Add its host
   SSH key (converted with `ssh-to-age`) or its user age key to `.sops.yaml`, run `sops updatekeys`
   for every file, and set `sops.age.sshKeyPaths` or `sops.age.keyFile` in its module. A machine
   with the sops module enabled and no recipient fails activation with "no key found".

Never copy `~/.gnupg` from another machine. The public key plus the card is the entire setup.

## Host 1: `ninja` (NixOS Workstation)

`ninja` enables both `mySystem.core.yubikey.enable = true` (via `modules/profiles/workstation.nix`)
and Home Manager's `home/dev.nix`.

### Why `disable-ccid = true` Is Required on NixOS

`modules/core/yubikey.nix` enables `services.pcscd.enable = true` for smartcard and PIV/OATH
tooling. By default, GnuPG's `scdaemon` attempts to claim the YubiKey directly via its built-in
`libusb` CCID driver first. When `pcscd` is already running and has claimed the USB CCID interface,
`scdaemon`'s internal CCID driver fails and returns:

```text
gpg: selecting card failed: No such device
gpg: OpenPGP card not available: No such device
```

Setting `disable-ccid = true` in `~/.gnupg/scdaemon.conf` (declared via
`programs.gpg.scdaemonSettings` in `home/dev.nix`) forces `scdaemon` to skip its internal `libusb`
driver and talk exclusively through `pcscd`.

### Declarative Configuration on `ninja`

**System level (`modules/core/yubikey.nix`):**

- `services.pcscd.enable = true;`
- `services.udev.packages = [ pkgs.yubikey-personalization ];`
- `security.pam.u2f.enable = true;` with `settings.cue = true;`
- `security.pam.services = { login.u2fAuth = true; sudo.u2fAuth = true; greetd.u2fAuth = true; };`
  - Uses `pam_u2f` with `control=sufficient`. Mappings live at `~/.config/Yubico/u2f_keys` (single
    credential, touch only, no PIN).

**User level (`home/dev.nix` and `home/shell/gpg-tty.sh`):**

- `programs.gpg.scdaemonSettings = { disable-ccid = true; };`
- `services.gpg-agent.defaultCacheTtl = 3600;` (1 hour User PIN cache window)
- `services.gpg-agent.grabKeyboardAndMouse = false;`
- **`pinentry-auto` wrapper**: `gpg-agent` runs as a systemd user service that inherits
  `WAYLAND_DISPLAY` from the graphical session. Without help, it would always open a GUI dialog
  (`pinentry-gnome3`), even when `gpg` is invoked inside a `tmux` pane on another workspace where
  the prompt goes unseen and times out.
  - `home/shell/gpg-tty.sh` runs before every shell prompt (`precmd` / `PROMPT_COMMAND`), updates
    `GPG_TTY`, and exports `PINENTRY_USER_DATA=curses` whenever `$TMUX` is set or no display is
    present (and `PINENTRY_USER_DATA=gui` otherwise).
  - `pinentry-auto` in `home/dev.nix` inspects `PINENTRY_USER_DATA`: if it contains `curses`, it
    execs `pinentry-curses` in the active pane; otherwise it execs `pinentry-gnome3`.

### Copy-Paste Setup for a Fresh NixOS Workstation

```bash
# 1. Build and activate the NixOS + Home Manager configuration
just build

# 2. Restart scdaemon/gpg-agent if they were already running
gpgconf --kill all

# 3. Import the public key (with subkeys)
curl -fsSL https://github.com/izaac.keys > /tmp/github-ssh.keys # SSH keys only
# For GPG public key, import from repo backup or keys.openpgp.org:
gpg --keyserver hkps://keys.openpgp.org --recv-keys 12D77955660CBE15071B7DB73183124333AB684C

# 4. Set ultimate ownertrust on your own primary fingerprint
echo "12D77955660CBE15071B7DB73183124333AB684C:6:" | gpg --import-ownertrust

# 5. Plug in YubiKey and populate local ssb> stubs
gpg --card-status

# 6. Verify secret stubs exist (ssb> for 54321CB1563EE61E, D1034A1D44262BC0, E5C447A6591778E2)
gpg --list-secret-keys --keyid-format=long

# 7. Test signing (prompts for User PIN via pinentry, then touch YubiKey)
echo "ninja test" | gpg --clearsign
```

---

## Host 2: `Mac` (macOS / `aarch64-darwin`)

On `Mac`, `hosts/Mac/configuration.nix` configures `home-manager` with `home/core.nix`,
`home/darwin/*`, `home/lazyvim.nix`, and `home/zed.nix`. It **does not** import `home/dev.nix`.

### Architecture Differences on macOS

1. **GPG Suite (`gpg-suite-no-mail`)**: Installed declaratively via `homebrew.casks` in
   `hosts/Mac/configuration.nix`. Provides MacGPG2 (`/usr/local/MacGPG2/bin/gpg`) and
   `pinentry-mac`.
2. **No `disable-ccid` Required**: macOS mediates smartcard access natively through CryptoTokenKit /
   macOS PC/SC, and MacGPG's `scdaemon` coexists with it out of the box.
3. **GUI Pinentry Dialog**: `pinentry-mac` presents a native macOS GUI window for the User PIN,
   which floats above all spaces and terminal windows regardless of whether you are inside `tmux` or
   Kitty.

### Copy-Paste Setup for a Fresh Mac

```bash
# 1. Apply the nix-darwin + Homebrew configuration (installs gpg-suite-no-mail)
just darwin-build

# 2. Import the public key (including the 2026-11-21 subkeys)
gpg --keyserver hkps://keys.openpgp.org --recv-keys 12D77955660CBE15071B7DB73183124333AB684C
# Or import directly from a file:
# gpg --import pub.asc

# 3. Mark primary key as ultimately trusted
echo "12D77955660CBE15071B7DB73183124333AB684C:6:" | gpg --import-ownertrust

# 4. Insert the YubiKey and run card-status first to create the ssb> stubs
gpg --card-status

# 5. Configure Git signing (since home/dev.nix is not imported on Mac)
git config --global user.name "Izaac Zavaleta"
git config --global user.email "izaac.zavaleta@suse.com"
git config --global user.signingkey 0x3183124333AB684C
git config --global commit.gpgsign true
git config --global tag.gpgsign true

# 6. Test signing (pinentry-mac GUI window appears -> enter User PIN -> touch YubiKey)
echo "mac test" | gpg --clearsign
```

---

## Host 3: `snail` (Slackware 15.0-current)

`snail` runs Slackware 15.0-current with GnuPG `2.5.24`. Two platform-specific details make
Slackware behave differently from NixOS and macOS:

1. **`scdaemon` Is Built Without `libusb`**: On Slackware, `scdaemon` has no internal CCID driver at
   all. Consequently, `pcscd` is **mandatory** (and `disable-ccid` is unnecessary because internal
   CCID is not compiled in).
2. **`pcsc-lite` Is Built With Polkit (`allow_any=no`)**: The default
   `/usr/share/polkit-1/actions/org.debian.pcsc-lite.policy` sets `<allow_any>no</allow_any>` and
   `<allow_inactive>no</allow_inactive>`, allowing only active local seat sessions
   (`allow_active=yes`). When you connect to `snail` over **SSH** (or log in without a local
   ConsoleKit/elogind graphical seat), Polkit silently denies `pcscd` access. GnuPG and `pcsc_scan`
   report:

   ```text
   gpg: selecting card failed: No such device
   # or from pcsc_scan:
   No smart card readers found.
   ```

### Fix 1: Polkit Rule for Group `plugdev`

Create `/etc/polkit-1/rules.d/20-pcsc-plugdev.rules` so any user in the `plugdev` group can access
`pcscd` and smartcards from any session (including SSH):

```javascript
polkit.addRule(function (action, subject) {
  if (
    (action.id == 'org.debian.pcsc-lite.access_pcsc' ||
      action.id == 'org.debian.pcsc-lite.access_card') &&
    subject.isInGroup('plugdev')
  ) {
    return polkit.Result.YES;
  }
});
```

Ensure your user is in `plugdev` (`id -nG | grep -qw plugdev`). Polkit picks up new `.rules` files
immediately, or restart `polkit` / `rc.pcscd` to be certain.

### Fix 2: Enable `rc.pcscd` (Watch Out for `slackpkg` Upgrades)

Slackware ships `/etc/rc.d/rc.pcscd` mode `0644` (disabled by default). More importantly,
**`slackpkg upgrade-all` resets `/etc/rc.d/rc.pcscd` permissions back to non-executable whenever the
`pcsc-lite` package is upgraded**.

```bash
sudo chmod +x /etc/rc.d/rc.pcscd
sudo /etc/rc.d/rc.pcscd start
```

If `gpg --card-status` suddenly fails on `snail` after a `slackpkg` run, check
`ls -l /etc/rc.d/rc.pcscd` first.

### Fix 3: `pinentry-tty` Configuration

For reliable prompts over SSH and local terminals without curses geometry glitches, configure
`~/.gnupg/gpg-agent.conf` on `snail` to use `pinentry-tty`:

```text
pinentry-program /usr/bin/pinentry-tty
default-cache-ttl 3600
```

Ensure the shell profile (`~/.zshrc` or `~/.bashrc`) exports `GPG_TTY=$(tty)`.

### Copy-Paste Setup for a Fresh Slackware Host (`snail`)

```bash
# 1. Ensure user is in plugdev
sudo usermod -aG plugdev "$USER"

# 2. Install the Polkit rule so SSH sessions can reach pcscd
sudo tee /etc/polkit-1/rules.d/20-pcsc-plugdev.rules >/dev/null <<'EOF'
polkit.addRule(function(action, subject) {
    if ((action.id == "org.debian.pcsc-lite.access_pcsc" ||
         action.id == "org.debian.pcsc-lite.access_card") &&
        subject.isInGroup("plugdev")) {
        return polkit.Result.YES;
    }
});
EOF

# 3. Enable and start pcscd (re-run chmod +x after any pcsc-lite slackpkg upgrade)
sudo chmod +x /etc/rc.d/rc.pcscd
sudo /etc/rc.d/rc.pcscd restart

# 4. Configure gpg-agent to use pinentry-tty
mkdir -p ~/.gnupg && chmod 700 ~/.gnupg
cat > ~/.gnupg/gpg-agent.conf <<'EOF'
pinentry-program /usr/bin/pinentry-tty
default-cache-ttl 3600
EOF
gpgconf --kill gpg-agent

# 5. Export GPG_TTY in shell rc
export GPG_TTY=$(tty)

# 6. Import public key, trust it, and initialize card stubs
gpg --keyserver hkps://keys.openpgp.org --recv-keys 12D77955660CBE15071B7DB73183124333AB684C
echo "12D77955660CBE15071B7DB73183124333AB684C:6:" | gpg --import-ownertrust
gpg --card-status

# 7. Test signing over SSH
echo "snail test" | gpg --clearsign
```
