# Agent Troubleshooting

> Tier 2 doc — loaded on demand when debugging.

---

## NixOS Config Issues

| Symptom                    | Cause                               | Fix                                                                                                                                                                                 |
| -------------------------- | ----------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `bashrc` syntax error      | Heredoc or array expression broken  | Validate: `nix eval ".#nixosConfigurations.$(hostname).config.home-manager.users.$USER.programs.bash.initExtra" --extra-experimental-features dynamic-derivations --raw \| bash -n` |
| `command not found`        | PATH missing in Distrobox           | Check Distrobox Shield in `home/shell/init.nix`                                                                                                                                     |
| `atuin` not saving history | DEBUG trap hijacked by another init | Ensure Monko Shield runs in `mkBefore`                                                                                                                                              |
| Build fails silently       | Flake eval error                    | Run `nix flake check` and `statix check .`                                                                                                                                          |
| Module option collision    | Two modules set same option         | Use `lib.mkForce` or `lib.mkDefault` to set priority                                                                                                                                |
| Home Manager rebuild fails | Stale generation                    | `nh clean all --keep 5` then rebuild                                                                                                                                                |

---

## Token / Context Issues

| Symptom                    | Cause                                    | Fix                                                                          |
| -------------------------- | ---------------------------------------- | ---------------------------------------------------------------------------- |
| Agent ignores instructions | AGENTS.md/CLAUDE.md too long             | Prune to essentials, move details to linked docs                             |
| Slow responses             | Context window near full                 | `/compact` or `/clear` and restart                                           |
| Repeated mistakes          | Failed approaches polluting context      | `/clear`, write better initial prompt                                        |
| Cache not hitting          | Format changed between requests          | Keep prompt structure identical across calls                                 |
| High token spend           | Loading irrelevant context every session | Use tiered architecture — see [agent-token-shield.md](agent-token-shield.md) |
