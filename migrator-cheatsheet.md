# macOS Migration Guide

 Quick reference for packing and unpacking

## OLD Machine - Pack

```bash
chmod +x ~/pack-migration.sh
./pack-migration.sh
```
Creates: `~/macos-migration-YYYYMMDD_HHMMSS.tar.gz`

## Transfer
Choose one method:
- **AirDrop** (easiest)
- **scp**: `scp user@old-machine:~/macos-migration-*.tar.gz .`
- **Cloud**: Upload to iCloud/Dropbox/Google Drive
- **USB**: Copy to external drive

## NEW Machine - Unpack
```bash
chmod +x ~/unpack-migration.sh
./unpack-migration.sh macos-migration-*.tar.gz
```

Then run the post-install commands printed by the script.

## Post-Install Commands (in order)
```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install packages from Brewfile
brew bundle install --file=~/migration-restore/Brewfile

# 3. Install Node.js (using NVM)
source /opt/homebrew/opt/nvm/nvm.sh
nvm install 24

# 4. Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# 5. Install Cursor extensions
xargs -n1 cursor --install-extension < ~/migration-restore/editors/cursor-extensions.txt

# 6. Install recommended extra packages
brew install ripgrep eza shellcheck starship tmux zoxide fzf \
  zsh-autosuggestions direnv zsh-fast-syntax-highlighting yq shfmt stylua poetry go

# 7. Apply macOS defaults
defaults write com.apple.dock autohide -bool false
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true
defaults write com.apple.finder AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write -g AppleKeyboardUIMode -int 2
defaults write -g AppleShowScrollBars -string Always
killall Dock && open /Applications/System\ Preferences.app

# 8. Add shell improvements to ~/.zshrc
echo 'eval "$(zoxide init zsh --cmd cd)"' >> ~/.zshrc
echo 'eval "$(starship init zsh)"' >> ~/.zshrc
echo 'source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh' >> ~/.zshrc
echo 'source /opt/homebrew/share/zsh-fast-syntax-highlighting/zsh-fast-syntax-highlighting.zsh' >> ~/.zshrc

# 9. Restart shell
exec zsh
```

## Manual Steps (after script)
1. **1Password** - Login and sync vaults
2. **Raycast** - Login (re-auth required)
3. **Docker/OrbStack** - Start and re-pull images if needed
4. **SSH keys** - `ssh-add ~/.ssh/id_ed25519_*`
5. **Git** - Verify config: `git config --global --list`

---

## What's Included in Backup

| Category | Items |
|----------|-------|
| **Shell** | `.zshrc`, `.zsh_history`, `.gitconfig`, `.npmrc`, `.profile` |
| **SSH** | All keys, `config`, `known_hosts` |
| **Homebrew** | `Brewfile` (all packages) |
| **Node** | NVM version, global npm packages |
| **Rust** | Toolchains, cargo tools |
| **Python** | pip packages |
| **Go** | Installed tools |
| **Editors** | Cursor, VS Code, Zed configs + extensions |
| **Apps** | gh CLI, OpenCode, Solana, Claude skills |
| **Fonts** | Jost font family |
| **Terminal** | iTerm2 plist |
| **Databases** | PostgreSQL dumps |
| **Docker** | Images list, volumes list |
| **macOS** | Dock, Finder, Screensaver defaults |

---

## Files Created

| File | Location |
|------|---------|
| `pack-migration.sh` | `~/pack-migration.sh` |
| `unpack-migration.sh` | `~/unpack-migration.sh` |
| `Migrator-cheatsheet.md` | This file (shown above) |
