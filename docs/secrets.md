# Secret Management with sops-nix

This project uses `sops-nix` to manage encrypted secrets (passwords, API keys, etc.) securely within the git repository.

## Prerequisites

To decrypt or edit secrets, you must have an **age identity file** generated from your SSH key.

Run this command once on each new machine:
```bash
mkdir -p ~/.config/sops/age
nix shell nixpkgs#ssh-to-age --command bash -c "ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt"
```

## Adding or Editing Secrets

1.  **Open the secrets file:**
    ```bash
    # From the root of the repo
    nix shell nixpkgs#sops -- sops secrets.yaml
    ```
2.  **Add your key-value pair:**
    The file is standard YAML. Add your secret at the top level:
    ```yaml
    my_new_secret: "super-secret-password"
    ```
3.  **Save and exit:**
    Sops will automatically encrypt the values using the public keys defined in `.sops.yaml`.

## Using Secrets in Nix

### 1. Define the secret in a module
In `modules/core/sops.nix` (or any NixOS module), declare the secret:
```nix
sops.secrets.my_new_secret = {
  owner = userConfig.username; # Optional: set permissions
};
```

### 2. Access the secret path
Secrets are decrypted at runtime and stored in `/run/secrets/`. You should always reference them via the config path:
```nix
# In a service or script:
passwordFile = config.sops.secrets.my_new_secret.path;
```

### 3. Example: Usage in a shell script
```nix
systemd.user.services.example = {
  script = ''
    PASSWORD=$(cat ${config.sops.secrets.my_new_secret.path})
    login-tool --password "$PASSWORD"
  '';
};
```

## Adding a New Machine or User
If you add a new computer or a new user's SSH key:
1.  Convert the public SSH key to age format: `echo "ssh-ed25519 ..." | ssh-to-age`.
2.  Add the age key to the `creation_rules` in `.sops.yaml`.
3.  Re-encrypt the existing secrets file: `sops updatekeys secrets.yaml`.
