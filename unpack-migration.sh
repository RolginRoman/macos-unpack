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

# --- [4] Internet Accounts ---
echo "[4] Internet Accounts..."
if [ -d "$RESTORE_DIR/internet-accounts" ] && [ "$(ls -A "$RESTORE_DIR/internet-accounts" 2>/dev/null)" ]; then
  mkdir -p ~/Library/Accounts
  cp -R "$RESTORE_DIR/internet-accounts/"* ~/Library/Accounts/ 2>/dev/null || warn "Could not restore Internet Accounts"
  chown -R $(whoami):staff ~/Library/Accounts 2>/dev/null || true
  log "Internet Accounts restored — restart required"
else
  log "(no Internet Accounts in archive — skipped)"
fi

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

configure_shell_stack() {
  local brew_prefix="$(brew --prefix 2>/dev/null || echo '/opt/homebrew')"
  
  add_to_zshrc 'zoxide init' 'eval "$(zoxide init zsh --cmd cd)"'
  add_to_zshrc 'starship init' 'eval "$(starship init zsh)"'
  add_to_zshrc 'fzf.zsh' '[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh'
  add_to_zshrc 'zsh-autosuggestions' "source ${brew_prefix}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  add_to_zshrc 'zsh-fast-syntax-highlighting' "source ${brew_prefix}/share/zsh-fast-syntax-highlighting/zsh-fast-syntax-highlighting.zsh"
  
  log "(All idempotent — safe to re-run)"
}

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

# --- [10] Auto-install toolchain ---
echo ""
echo "=== AUTO-INSTALLING TOOLCHAIN ==="

export HOMEBREW_NO_AUTO_UPDATE=1

install_homebrew() {
  if command -v brew &>/dev/null; then
    log "Homebrew already installed"
    return 0
  fi
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    log "Homebrew found, added to PATH"
    return 0
  fi
  log "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    grep -q 'brew shellenv' ~/.zprofile 2>/dev/null || echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  command -v brew &>/dev/null || warn "Homebrew installation failed"
}

install_brewfile() {
  local brewfile="$RESTORE_DIR/Brewfile"
  local filtered_brewfile="$RESTORE_DIR/Brewfile.filtered"
  local deprecated="openssl@1.1|openssl@1|python@3.9|python@3.8|node@14|node@16"
  
  if [[ ! -f "$brewfile" ]]; then
    log "(no Brewfile in archive — skipped)"
    return 0
  fi
  if ! command -v brew &>/dev/null; then
    warn "Cannot install Brewfile — Homebrew not available"
    return 1
  fi
  
  grep -Ev "^brew \"($deprecated)\"" "$brewfile" > "$filtered_brewfile"
  
  log "Installing packages from Brewfile..."
  if brew bundle install --file="$filtered_brewfile" 2>&1; then
    log "Brewfile installed successfully"
  else
    warn "Some Brewfile packages failed — check output above"
  fi
}

install_fnm() {
  if command -v fnm &>/dev/null; then
    log "fnm already installed"
  else
    if command -v brew &>/dev/null; then
      log "Installing fnm via Homebrew..."
      brew install fnm 2>/dev/null || warn "fnm install failed"
    fi
  fi
  if command -v fnm &>/dev/null; then
    export PATH="$HOME/.fnm:$PATH"
    eval "$(fnm env --shell bash 2>/dev/null)" || true
    local node_ver
    node_ver=$(cat "$RESTORE_DIR/fnm-node-version.txt" 2>/dev/null || echo "lts")
    log "Installing Node $node_ver via fnm..."
    fnm install "$node_ver" 2>/dev/null || fnm install --lts 2>/dev/null || warn "fnm Node install failed"
    fnm use "$node_ver" 2>/dev/null || fnm use --lts 2>/dev/null || true
    grep -q 'fnm env' ~/.zshrc 2>/dev/null || echo 'eval "$(fnm env --use-on-cd)"' >> ~/.zshrc
  fi
}

install_pnpm() {
  if command -v pnpm &>/dev/null; then
    log "pnpm already installed"
    return 0
  fi
  if command -v corepack &>/dev/null; then
    log "Enabling pnpm via corepack..."
    corepack enable 2>/dev/null && corepack prepare pnpm@latest --activate 2>/dev/null || warn "pnpm install failed"
  else
    log "(corepack not available — install Node first)"
  fi
}

install_uv() {
  if command -v uv &>/dev/null; then
    log "uv already installed"
    return 0
  fi
  log "Installing uv..."
  if curl -LsSf https://astral.sh/uv/install.sh | sh 2>/dev/null; then
    export PATH="$HOME/.local/bin:$PATH"
    log "uv installed successfully"
  else
    warn "uv install failed"
  fi
}

install_rust() {
  if command -v rustc &>/dev/null; then
    log "Rust already installed"
    return 0
  fi
  log "Installing Rust..."
  if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 2>/dev/null; then
    source "$HOME/.cargo/env" 2>/dev/null || true
    log "Rust installed successfully"
  else
    warn "Rust install failed"
  fi
}

install_cursor_extensions() {
  local ext_file="$RESTORE_DIR/editors/cursor-extensions.txt"
  if [[ ! -f "$ext_file" ]]; then
    return 0
  fi
  if ! command -v cursor &>/dev/null; then
    log "(cursor CLI not available — skip extensions)"
    return 0
  fi
  log "Installing Cursor extensions..."
  local count=0
  while IFS= read -r ext; do
    [[ -n "$ext" ]] || continue
    cursor --install-extension "$ext" 2>/dev/null && ((count++))
  done < "$ext_file"
  log "Installed $count Cursor extensions"
}

install_essential_apps() {
  local apps=(
    "iterm2"
    "orbstack"
    "raycast"
    "1password"
    "1password-cli"
    "tailscale"
    "obsidian"
    "betterdisplay"
    "aldente"
    "claude"
  )

  if ! command -v brew &>/dev/null; then
    warn "Homebrew not available — cannot install essential apps"
    return 1
  fi

  log "Installing essential apps via Homebrew..."
  local installed=0
  local skipped=0
  for app in "${apps[@]}"; do
    if brew list --cask "$app" &>/dev/null; then
      log "$app already installed"
      ((skipped++))
    else
      if brew install --cask "$app" 2>&1; then
        ((installed++))
      else
        warn "Failed to install $app"
      fi
    fi
  done

  log "Apps: $installed installed, $skipped already present"
}

add_ssh_keys() {
  local keys=()
  for key in ~/.ssh/id_ed25519 ~/.ssh/id_ed25519_* ~/.ssh/id_rsa ~/.ssh/id_rsa_* ~/.ssh/id_ecdsa ~/.ssh/id_ecdsa_*; do
    [[ -f "$key" && ! "$key" == *.pub ]] && keys+=("$key")
  done
  if [[ ${#keys[@]} -gt 0 ]]; then
    log "Adding SSH keys to agent (may prompt for passphrase)..."
    ssh-add "${keys[@]}" 2>/dev/null || log "(SSH agent add skipped or needs passphrase)"
  fi
}

install_homebrew
install_brewfile
install_fnm
install_pnpm
install_uv
install_rust
install_cursor_extensions
install_essential_apps
configure_shell_stack
add_ssh_keys

echo ""
echo "=== RESTORE COMPLETE ==="
echo ""
echo "NEXT STEPS:"
echo ""
echo "  1. Login to apps:"
echo "     - 1Password"
echo "     - Raycast"
echo "     - OrbStack"
echo ""
echo "  2. Restart shell:"
echo "     exec zsh"
echo ""

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo "⚠ WARNINGS (${#ERRORS[@]} steps had issues):"
  for err in "${ERRORS[@]}"; do
    echo "  • $err"
  done
  echo ""
fi
