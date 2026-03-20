# macOS Migration Quick Guide

Migrate your dev environment between Macs — configs, shell, editors, SSH keys, databases.

## ON OLD MACHINE

```bash
chmod +x pack-migration.sh
./pack-migration.sh
```

Creates `~/macos-migration-YYYYMMDD_HHMMSS.tar.gz`.

Transfer to new machine via AirDrop, scp, cloud, or USB.

---

## ON NEW MACHINE

### 1. Run unpack script
```bash
chmod +x unpack-migration.sh
./unpack-migration.sh ~/macos-migration-*.tar.gz
```

The script auto-restores configs, shell stack (zoxide, starship, fzf), and macOS defaults. It prints the remaining manual steps.

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

### 4. Install Node (fnm)
```bash
fnm install --lts
fnm use $(cat ~/migration-restore/fnm-node-version.txt 2>/dev/null || echo 'lts')
```

### 5. Install pnpm
```bash
corepack enable && corepack prepare pnpm@latest --activate
```

### 6. Install uv (Python)
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### 7. Install Rust
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source ~/.cargo/env
```

### 8. Install Cursor extensions
```bash
xargs -n1 cursor --install-extension < ~/migration-restore/editors/cursor-extensions.txt
```

### 9. Login to apps
- 1Password
- Raycast
- OrbStack

### 10. Add SSH keys
```bash
ssh-add ~/.ssh/id_ed25519_*
```

### 11. Restart shell
```bash
exec zsh
```

---

## What gets migrated

| Category | Pack | Unpack |
|----------|------|--------|
| **Shell** | `.zshrc`, `.zsh_history`, `.gitconfig`, `.npmrc` | Restored to `~/` |
| **SSH** | All keys, `config`, `known_hosts` | Restored to `~/.ssh/` |
| **Homebrew** | `Brewfile` | Manual `brew bundle install` |
| **Node** | fnm version, global npm packages | Manual fnm install |
| **Rust** | Toolchains, cargo tools | Manual rustup install |
| **Python** | uv/pip packages list | Manual uv install |
| **Go** | Installed tools list | — |
| **Editors** | Cursor, VS Code, Zed configs + extensions | Restored automatically |
| **Apps** | gh CLI, OpenCode, Solana, Claude skills | Restored automatically |
| **Fonts** | All fonts | Restored to `~/Library/Fonts/` |
| **Databases** | PostgreSQL dumps | Restored if psql available |
| **Docker** | Images list, volumes list | — |
| **macOS defaults** | Dock, Finder, Screensaver | Applied automatically |
| **Shell stack** | — | zoxide, starship, fzf, autosuggestions, syntax-hl added to `.zshrc` |

## Apps to install manually

- **Raycast** — https://raycast.com/download
- **iTerm2** — `brew install --cask iterm2`
- **1Password** — https://1password.com/downloads
- **OrbStack** — `brew install --cask orbstack`
- **Claude Desktop** — https://claude.ai/download
- **Obsidian** — https://obsidian.md/download

## OPTIONAL: Solana / Go tools

```bash
# Solana CLI
sh -c "$(curl -sSfL https://release.ananza.xyz/stable/install)"

# Anchor (AVM)
cargo install --git https://github.com/coral-xyz/anchor avm --locked --force
avm install 0.30.1

# Go tools
go install github.com/kyleconroy/sqlc/cmd/sqlc@latest
go install github.com/rustwizard/cleaver/cmd/cleaver@latest
```
