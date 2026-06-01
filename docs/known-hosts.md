# GitHub SSH Host Key Pinning

Pins github.com SSH host keys (ED25519, ECDSA, RSA) at the system level
via `programs.ssh.knownHosts`. First `git clone` over SSH never prompts
for host key acceptance, and the connection is immune to first connect
TOFU MITM against github.com.

Enabled on ninja and windy via `mySystem.core."known-hosts".enable`.

## Where it earns its keep

After a fresh install or a disko rebuild the per user
`~/.ssh/known_hosts` is empty, so the first SSH to GitHub would
otherwise prompt. Unattended SSH from scripts, systemd units, or CI
runners has no way to answer that prompt and fails. On hostile or
unfamiliar networks (road mode) an attacker could serve a forged key
during the very first connect; pinning closes that window.

## What it does not cover

A rotation of GitHub's own keys requires updating the module file. SSH
to forks, mirrors, or other Git providers (Codeberg, Gitea) still
relies on TOFU. Any host other than github.com is unaffected.

## Updating

Source of truth is `https://api.github.com/meta`. Replace the matching
`publicKey` string in `modules/core/known-hosts.nix` and rebuild.

## Scope

NixOS hosts only. The Mac is not covered. Add an equivalent
`programs.ssh.knownHosts` entry in `hosts/Mac/configuration.nix` if
that becomes useful.
