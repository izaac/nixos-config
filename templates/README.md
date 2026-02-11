# Development Environment Templates

This directory contains both **golden master shells** (ephemeral) and **project templates** (scaffolding) for various programming languages.

## Quick Reference

### Golden Master Shells (Ephemeral)

Quick, one-off shells without creating files:

```bash
# Rust
nix develop github:<username>/nixos-config?dir=templates#rust

# C
nix develop github:<username>/nixos-config?dir=templates#c

# C++ (Clang)
nix develop github:<username>/nixos-config?dir=templates#cpp

# Python (default)
nix develop github:<username>/nixos-config?dir=templates#python

# Python (specific version)
nix develop github:<username>/nixos-config?dir=templates#python_312

# Node.js (default)
nix develop github:<username>/nixos-config?dir=templates#node

# Node.js (specific version)
nix develop github:<username>/nixos-config?dir=templates#node_22
```

### Project Templates (devenv-based)

Create a new project with full devenv configuration:

```bash
# Initialize a new Rust project
mkdir my-rust-project && cd my-rust-project
nix flake init -t github:<username>/nixos-config?dir=templates#rust
direnv allow  # Auto-loads the environment

# Initialize a new C project
mkdir my-c-project && cd my-c-project
nix flake init -t github:<username>/nixos-config?dir=templates#c
direnv allow

# Initialize a new C++ project
mkdir my-cpp-project && cd my-cpp-project
nix flake init -t github:<username>/nixos-config?dir=templates#cpp
direnv allow
```

### Shell Functions (Quick Setup)

If this config is installed locally, use these convenience functions:

#### Node.js Projects

```bash
# New project
mkdir my-app && cd my-app
npm init -y          # Create package.json first
ninit                # Creates .envrc, auto-installs dependencies

# With specific version
ninit 22             # Use Node.js 22

# Existing project
cd ~/existing-node-project
ninit                # Loads environment, installs missing dependencies
```

#### Python Projects

```bash
# New project
mkdir my-app && cd my-app
uv init              # Initialize with uv
pinit                # Creates .envrc, sets up environment

# With specific version
pinit 312            # Use Python 3.12

# Existing project with requirements.txt
cd ~/existing-python-project
pinit                # Loads environment, creates venv if needed
```

#### Rust Projects

```bash
# New project
mkdir my-app && cd my-app
cargo init           # Initialize Rust project
rinit                # Creates .envrc, loads Rust toolchain

# Existing project
cd ~/existing-rust-project
rinit                # Loads environment immediately
```

#### C Projects

```bash
# New project
mkdir my-app && cd my-app
cinit                # Creates .envrc, loads GCC toolchain
# Now create your CMakeLists.txt or Makefile

# Existing project
cd ~/existing-c-project
cinit                # Loads environment with gcc, cmake, gdb, etc.
```

#### C++ Projects

```bash
# New project
mkdir my-app && cd my-app
cppinit              # Creates .envrc, loads Clang toolchain
# Now create your CMakeLists.txt or Makefile

# Existing project
cd ~/existing-cpp-project
cppinit              # Loads environment with clang, cmake, lldb, etc.
```

**Note:** These functions create a `.envrc` file in your current directory. Add it to `.gitignore` if you don't want to commit it.

---

## Template Details

### Rust Template

**Features:**
- Rust stable toolchain (rustc, cargo, rust-analyzer, clippy, rustfmt)
- Additional tools: cargo-watch, cargo-edit, cargo-audit, cargo-outdated, bacon
- Pre-configured scripts: `build`, `test`, `run`, `watch`

**Usage:**
```bash
nix flake init -t github:<username>/nixos-config?dir=templates#rust
direnv allow
build  # Run cargo build
watch  # Run bacon (background checker)
```

**Customization:**
Edit `devenv.nix` to:
- Change Rust channel (stable/nightly/beta)
- Add more cargo tools
- Enable pre-commit hooks (rustfmt, clippy)

---

### C Template

**Features:**
- GCC compiler with cmake, ninja, pkg-config
- Debugging: gdb, valgrind
- Common libraries: openssl, zlib, curl, sqlite
- Pre-configured scripts: `build`, `clean`, `test`, `debug`

**Usage:**
```bash
nix flake init -t github:<username>/nixos-config?dir=templates#c
direnv allow
build  # cmake + ninja build
debug  # launch gdb
```

**Customization:**
Edit `devenv.nix` to:
- Add/remove libraries in `packages = [ ... ]`
- Modify build scripts
- Add project-specific environment variables

**Important:** All libraries must be explicitly declared! See "Adding Libraries" below.

---

### C++ Template

**Features:**
- Clang toolchain (clang, clangd, clang-format, clang-tidy, lldb)
- Build tools: cmake, ninja, pkg-config
- Common libraries: openssl, zlib, curl, sqlite, boost
- Analysis: valgrind, cppcheck
- Pre-configured scripts: `build`, `clean`, `test`, `debug`, `format`, `lint`

**Usage:**
```bash
nix flake init -t github:<username>/nixos-config?dir=templates#cpp
direnv allow
build   # cmake + ninja build
format  # clang-format
lint    # clang-tidy
```

**Customization:**
Edit `devenv.nix` to:
- Switch to GCC (uncomment gcc/gdb, comment clang/lldb)
- Add/remove libraries
- Modify linter rules

---

## Adding Libraries to C/C++ Projects

On NixOS, there's no `/usr/lib` or `/usr/include`. You MUST explicitly declare all dependencies.

### Example: Adding SDL2 to a C project

Edit `devenv.nix`:
```nix
packages = with pkgs; [
  # ... existing packages ...
  SDL2
  SDL2_image
  SDL2_mixer
];
```

Then rebuild:
```bash
direnv reload
```

Now `gcc` and `cmake` will automatically find SDL2 headers and libraries.

### Common Libraries

Available in `pkgs`:
- Graphics: `SDL2`, `SDL2_image`, `glfw`, `vulkan-loader`, `mesa`
- Compression: `zlib`, `bzip2`, `xz`, `zstd`
- Crypto: `openssl`, `libsodium`, `gnutls`
- Networking: `curl`, `libssh2`, `nghttp2`
- Database: `sqlite`, `postgresql`, `mysql80`
- XML/JSON: `libxml2`, `rapidjson`, `nlohmann_json`, `pugixml`
- Math: `gsl`, `eigen`, `blas`, `lapack`

Search for packages: `nix search nixpkgs <package-name>`

---

## devenv.sh Features

All project templates use [devenv.sh](https://devenv.sh), which provides:

### 1. Custom Scripts
```nix
scripts.mycmd.exec = "echo 'Hello from mycmd'";
```

Then run: `mycmd`

### 2. Background Processes
```nix
processes.watch.exec = "cargo watch -x check";
```

Runs automatically when entering the shell.

### 3. Pre-commit Hooks
```nix
pre-commit.hooks = {
  rustfmt.enable = true;
  clippy.enable = true;
};
```

### 4. Services (Databases, Redis, etc.)
```nix
services.postgres = {
  enable = true;
  initialDatabases = [{ name = "mydb"; }];
};
```

See: https://devenv.sh/reference/options/

---

## Workflow

### One-time Project Setup

```bash
# 1. Create project directory
mkdir my-project && cd my-project

# 2. Initialize from template
nix flake init -t github:<username>/nixos-config?dir=templates#rust

# 3. Allow direnv (auto-loads shell on cd)
direnv allow

# 4. Customize devenv.nix for your project
vim devenv.nix

# 5. Start coding - environment auto-loads!
```

### Daily Development

```bash
cd my-project  # direnv auto-loads the shell
build          # run custom scripts
test
```

---

## Troubleshooting

### "direnv: error .envrc is blocked"
Run: `direnv allow`

### "Cannot find library X"
Add it to `devenv.nix` packages:
```nix
packages = with pkgs; [ yourLibrary ];
```

### "Command not found: build/test/etc"
These are custom scripts defined in `devenv.nix`. Make sure devenv loaded:
```bash
direnv reload
```

### Check what's in your environment
```bash
env | grep NIX
pkg-config --list-all
```

### "npm install failed: ENOENT package.json" (or similar errors)
You ran `ninit`/`pinit` in a directory without project files. The functions only work in project directories.

**Fix:**
```bash
# Remove the incorrect .envrc
rm .envrc

# Then either:
# 1. Initialize the project first
npm init -y && ninit

# 2. Or move to the correct project directory
cd ~/my-actual-project && ninit
```

### Accidentally created .envrc in the wrong place
```bash
# Just delete it
rm .envrc

# If direnv already loaded it, reload the parent directory
cd .. && cd -
```

---

## Further Reading

- [devenv.sh documentation](https://devenv.sh)
- [NixOS packages search](https://search.nixos.org/packages)
- [Nix language basics](https://nix.dev/tutorials/nix-language)

---

## Maintenance

### Update devenv.sh
```bash
cd templates
nix flake update
```

### Update golden master shells
Edit `templates/flake.nix` devShells section.

### Add new template
1. Create new directory: `mkdir templates/mylang`
2. Add files: `flake.nix`, `devenv.nix`, `.envrc`
3. Register in `templates/flake.nix`:
   ```nix
   templates.mylang = {
     path = ./mylang;
     description = "MyLang development environment";
   };
   ```
