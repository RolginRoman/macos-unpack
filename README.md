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

The script auto-restores configs, shell stack (zoxide, starship, fzf), macOS defaults, and **auto-installs the full toolchain**:
- Homebrew (if not present)
- All packages from Brewfile
- fnm + Node (from saved version or LTS)
- pnpm (via corepack)
- uv (Python)
- Rust (rustup)
- Cursor extensions
- SSH keys to agent

### 2. Login to apps
- 1Password
- Raycast
- OrbStack

### 3. Restart shell
```bash
exec zsh
```

---

## What gets migrated

| Category | Pack | Unpack |
|----------|------|--------|
| **Shell** | `.zshrc`, `.zsh_history`, `.bashrc`, `.bash_aliases`, `.bash_history`, `.inputrc`, `.gitconfig`, `.npmrc` | Restored to `~/` |
| **SSH** | All keys, `config`, `known_hosts` | Restored to `~/.ssh/` |
| **Homebrew** | `Brewfile` | Auto-installed (if not present) |
| **Node** | fnm version, global npm packages | Auto-installed (fnm + Node + pnpm) |
| **Rust** | Toolchains, cargo tools | Auto-installed (rustup) |
| **Python** | uv/pip packages list | Auto-installed (uv) |
| **Go** | Installed tools list | — |
| **Editors** | Cursor, VS Code, Zed configs + extensions | Restored + extensions auto-installed |
| **Apps** | gh CLI, OpenCode, Solana, Claude skills | Restored automatically |
| **Fonts** | All fonts | Restored to `~/Library/Fonts/` |
| **Databases** | PostgreSQL dumps | Restored if psql available |
| **Docker** | Images list, volumes list | — |
| **macOS defaults** | Dock, Finder, key repeat, screenshot location | Applied automatically |
| **Shell stack** | — | zoxide, starship, fzf, autosuggestions, syntax-hl added to `.zshrc` |

## Apps to install manually

- **Raycast** — https://raycast.com/download
- **iTerm2** — `brew install --cask iterm2`
- **1Password** — https://1password.com/downloads
- **OrbStack** — `brew install --cask orbstack`
- **Claude Desktop** — https://claude.ai/download
- **Obsidian** — https://obsidian.md/download
- **Tailscale** — `brew install --cask tailscale` (VPN/mesh networking)
- **BetterDisplay** — https://betterdisplay.pro (HiDPI, display control)
- **AlDente** — https://apphousekitchen.com (battery health for MacBook)

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
