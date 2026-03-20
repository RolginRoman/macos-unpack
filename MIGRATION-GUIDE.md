# macOS Migration Quick Guide

## ON OLD MACHINE

```bash
chmod +x pack-migration.sh
./pack-migration.sh
```

Transfer `~/macos-migration-*.tar.gz` to new machine.

---

## ON NEW MACHINE

### 1. Run unpack script
```bash
chmod +x unpack-migration.sh
./unpack-migration.sh ~/macos-migration-*.tar.gz
```

### 2. Install Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### 3. Install packages
```bash
brew bundle install --file=~/migration-restore/Brewfile
```

### 4. Install Node
```bash
source /opt/homebrew/opt/nvm/nvm.sh
nvm install 24
```

### 5. Install Rust
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source ~/.cargo/env
```

### 6. Install Cursor extensions
```bash
xargs -n1 cursor --install-extension < ~/migration-restore/editors/cursor-extensions.txt
```

### 7. Add SSH keys
```bash
ssh-add ~/.ssh/id_ed25519_*
```

### 8. Login to apps
- 1Password
- Raycast  
- Docker/OrbStack

### 9. Restart shell
```bash
exec zsh
```

---

## OPTIONAL: Install additional tools

```bash
# Solana CLI
sh -c "$(curl -sSfL https://release.anza.xyz/stable/install)"

# Anchor (AVM)
cargo install --git https://github.com/coral-xyz/anchor avm --locked --force
avm install 0.30.1

# Go tools
go install github.com/kyleconroy/sqlc/cmd/sqlc@latest
go install github.com/rustwizard/cleaver/cmd/cleaver@latest
```
