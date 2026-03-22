#!/bin/bash
# Resilient macOS migration unpack script
# Continues on errors — reports what failed at the end

ARCHIVE="$1"
RESTORE_DIR="$HOME/migration-restore"
ERRORS=()

if [ -z "$ARCHIVE" ]; then
  echo "Usage: ./unpack-migration.sh <archive.tar.gz>"
  exit 1
fi

# --- helpers ---
log()  { echo "  $1"; }
warn() { echo "  ⚠ $1"; ERRORS+=("$1"); }
copy() { # copy <src> <dst> — mkdir -p dst dir, copy, warn on failure
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  cp -RL "$src" "$dst" 2>/dev/null || warn "Could not copy $(basename "$src") → $dst"
}

echo "=== macOS Migration Unpack Script ==="
echo "Archive: $ARCHIVE"
echo ""

mkdir -p "$RESTORE_DIR"
if ! tar -xzf "$ARCHIVE" -C "$RESTORE_DIR" 2>/dev/null; then
  echo "ERROR: Failed to extract archive (corrupt or wrong format?)"
  exit 1
fi
echo "Extracted to: $RESTORE_DIR"

echo ""
echo "=== RESTORING CONFIGS ==="

# --- [1] Shell configs ---
echo "[1] Shell configs..."
for f in "$RESTORE_DIR/configs/"*; do
  [ -f "$f" ] || continue
  cp "$f" ~ 2>/dev/null || warn "Could not restore $(basename "$f")"
done

# --- [2] SSH keys ---
echo "[2] SSH keys..."
if [ -d "$RESTORE_DIR/ssh" ]; then
  mkdir -p ~/.ssh
  chmod 700 ~/.ssh
  for f in "$RESTORE_DIR/ssh/"*; do
    [ -f "$f" ] || continue
    cp "$f" ~/.ssh/ 2>/dev/null || warn "Could not restore $(basename "$f")"
  done
  chmod 600 ~/.ssh/id_* 2>/dev/null || true
  chmod 644 ~/.ssh/*.pub 2>/dev/null || true
else
  log "(no SSH keys in archive — skipped)"
fi

# --- [3] Fonts ---
echo "[3] Fonts..."
if [ -d "$RESTORE_DIR/fonts" ] && [ "$(ls -A "$RESTORE_DIR/fonts" 2>/dev/null)" ]; then
  mkdir -p ~/Library/Fonts
  cp "$RESTORE_DIR/fonts/"* ~/Library/Fonts/ 2>/dev/null || warn "Could not restore fonts"
else
  log "(no fonts in archive — skipped)"
fi

# --- [4] iTerm2 ---
echo "[4] (skipped — iTerm2 plist not in backup)"

# --- [5] Editor configs ---
echo "[5] Editor configs..."
if [ -d "$RESTORE_DIR/editors/cursor" ]; then
  copy "$RESTORE_DIR/editors/cursor/." ~/Library/Application\ Support/Cursor/User/
else
  log "(no Cursor config — skipped)"
fi

if [ -d "$RESTORE_DIR/editors/vscode" ]; then
  copy "$RESTORE_DIR/editors/vscode/." ~/Library/Application\ Support/Code/User/
else
  log "(no VS Code config — skipped)"
fi

if [ -d "$RESTORE_DIR/editors/zed" ]; then
  copy "$RESTORE_DIR/editors/zed/." ~/.config/zed/
else
  log "(no Zed config — skipped)"
fi

# --- [6] App configs ---
echo "[6] App configs..."
if [ -f "$RESTORE_DIR/app-configs/gh-config.yml" ]; then
  mkdir -p ~/.config/gh
  cp "$RESTORE_DIR/app-configs/gh-config.yml" ~/.config/gh/config.yml 2>/dev/null || warn "Could not restore gh config"
fi

for app in opencode solana; do
  if [ -d "$RESTORE_DIR/app-configs/$app" ]; then
    copy "$RESTORE_DIR/app-configs/$app/." ~/.config/$app/
  fi
done

if [ -d "$RESTORE_DIR/app-configs/claude-skills" ]; then
  copy "$RESTORE_DIR/app-configs/claude-skills/." ~/.claude/skills/
fi

if [ -f "$RESTORE_DIR/app-configs/local-bin-env" ]; then
  mkdir -p ~/.local/bin
  cp "$RESTORE_DIR/app-configs/local-bin-env" ~/.local/bin/env 2>/dev/null || warn "Could not restore ~/.local/bin/env"
fi

# --- [7] Database dumps ---
echo "[7] Database dumps..."
if [ -d "$RESTORE_DIR/databases" ] && ls "$RESTORE_DIR/databases/"*.sql >/dev/null 2>&1; then
  if command -v psql &>/dev/null; then
    for dump in "$RESTORE_DIR/databases/"*.sql; do
      [ -f "$dump" ] || continue
      dbname=$(basename "$dump" .sql)
      log "Restoring: $dbname"
      psql -d postgres -c "CREATE DATABASE $dbname;" 2>/dev/null || true
      psql -d "$dbname" -f "$dump" 2>/dev/null || warn "Could not restore $dbname (may need manual restore)"
    done
  else
    log "(psql not found — restore databases manually after installing PostgreSQL)"
  fi
else
  log "(no database dumps in archive — skipped)"
fi

# --- [8] Shell stack (auto) ---
echo ""
echo "=== AUTO-CONFIGURING SHELL STACK ==="

# Ensure .zshrc exists
touch ~/.zshrc

add_to_zshrc() {
  local marker="$1" line="$2"
  if ! grep -qF "$marker" ~/.zshrc 2>/dev/null; then
    echo "$line" >> ~/.zshrc
    log "Added: $line"
  else
    log "Already present: $marker"
  fi
}

add_to_zshrc 'zoxide init' 'eval "$(zoxide init zsh --cmd cd)"'
add_to_zshrc 'starship init' 'eval "$(starship init zsh)"'
add_to_zshrc 'fzf.zsh' '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh'
add_to_zshrc 'zsh-autosuggestions' 'source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh'
add_to_zshrc 'zsh-fast-syntax-highlighting' 'source /opt/homebrew/share/zsh-fast-syntax-highlighting/zsh-fast-syntax-highlighting.zsh'

log "(All idempotent — safe to re-run)"

# --- [9] macOS defaults (auto) ---
echo ""
echo "=== APPLYING MACOS DEFAULTS ==="

# Dock
defaults write com.apple.dock autohide -bool true 2>/dev/null || warn "Could not set Dock autohide"
defaults write com.apple.dock minimize-to-application -bool true 2>/dev/null || warn "Could not set Dock minimize"
defaults write com.apple.dock autohide-time-modifier -float 0.5 2>/dev/null || warn "Could not set Dock animation speed"
defaults write com.apple.dock autohide-delay -int 0 2>/dev/null || warn "Could not set Dock show delay"

# Finder
defaults write com.apple.finder AppleShowAllFiles -bool true 2>/dev/null || warn "Could not show hidden files"
defaults write com.apple.finder AppleShowAllExtensions -bool true 2>/dev/null || warn "Could not show extensions"
defaults write com.apple.finder ShowPathbar -bool true 2>/dev/null || warn "Could not show path bar"

# Global
defaults write -g AppleKeyboardUIMode -int 2 2>/dev/null || warn "Could not set keyboard UI mode"
defaults write -g AppleShowScrollBars -string Always 2>/dev/null || warn "Could not set scroll bars"
defaults write -g ApplePressAndHoldEnabled -bool false 2>/dev/null || warn "Could not enable key repeat"

# Screenshots
mkdir -p ~/Screenshots 2>/dev/null
defaults write com.apple.screencapture location ~/Screenshots 2>/dev/null || warn "Could not set screenshot location"

killall Dock 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

# --- Done ---
echo ""
echo "=== RESTORE COMPLETE ==="
echo ""
echo "MANUAL STEPS REQUIRED:"
echo ""
echo "  1. Install Homebrew:"
echo "     /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
echo ""
echo "  2. Install packages from Brewfile:"
[ -f "$RESTORE_DIR/Brewfile" ] && echo "     brew bundle install --file=$RESTORE_DIR/Brewfile" || echo "     (no Brewfile in archive)"
echo ""
echo "  3. Install Node (fnm):"
echo "     fnm install --lts"
echo "     fnm use \$(cat $RESTORE_DIR/fnm-node-version.txt 2>/dev/null || echo 'lts')"
echo ""
echo "  4. Install pnpm:"
echo "     corepack enable && corepack prepare pnpm@latest --activate"
echo ""
echo "  5. Install uv (Python):"
echo "     curl -LsSf https://astral.sh/uv/install.sh | sh"
echo ""
echo "  6. Install Rust:"
echo "     curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
echo ""
if [ -f "$RESTORE_DIR/editors/cursor-extensions.txt" ]; then
echo "  7. Install Cursor extensions:"
echo "     xargs -n1 cursor --install-extension < $RESTORE_DIR/editors/cursor-extensions.txt"
echo ""
fi
echo "  8. Login to apps:"
echo "     - 1Password"
echo "     - Raycast"
echo "     - OrbStack"
echo ""
echo "  9. Add SSH keys to agent:"
echo "     ssh-add ~/.ssh/id_ed25519_*"
echo ""
echo "  10. Restart shell:"
echo "      exec zsh"
echo ""
echo "========================================="
echo "APPS TO INSTALL MANUALLY (not in Brewfile):"
echo "========================================="
echo "  • Raycast        - https://raycast.com/download"
echo "  • iTerm2         - brew install --cask iterm2"
echo "  • 1Password      - https://1password.com/downloads"
echo "  • OrbStack       - brew install --cask orbstack"
echo "  • Claude Desktop - https://claude.ai/download"
echo "  • Obsidian       - https://obsidian.md/download"
echo "  • Tailscale      - brew install --cask tailscale (or App Store)"
echo "  • BetterDisplay  - https://betterdisplay.pro (HiDPI, display control)"
echo "  • AlDente        - https://apphousekitchen.com (battery health for MacBook)"
echo "========================================="

# --- Error summary ---
if [ ${#ERRORS[@]} -gt 0 ]; then
  echo ""
  echo "⚠ WARNINGS (${#ERRORS[@]} steps had issues):"
  for err in "${ERRORS[@]}"; do
    echo "  • $err"
  done
  echo ""
fi
