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

```bash
curl -sSL https://raw.githubusercontent.com/RolginRoman/macos-unpack/main/unpack-migration.sh | bash -s -- ~/macos-migration-*.tar.gz
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
- **Essential apps**: iTerm2, OrbStack, Raycast, 1Password, Tailscale, Obsidian, BetterDisplay, AlDente, Claude

### Login to apps
- 1Password
- Raycast
- OrbStack

### Restart shell
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
| **Internet Accounts** | `~/Library/Accounts/` (email, calendars, etc.) | Restored to `~/Library/Accounts/` |
| **Databases** | PostgreSQL dumps | Restored if psql available |
| **Docker** | Images list, volumes list | — |
| **macOS defaults** | Dock, Finder, key repeat, screenshot location | Applied automatically |
| **Shell stack** | — | zoxide, starship, fzf, autosuggestions, syntax-hl added to `.zshrc` |

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
