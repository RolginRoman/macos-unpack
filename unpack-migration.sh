#!/bin/bash
set -e

ARCHIVE="$1"
RESTORE_DIR="$HOME/migration-restore"

if [ -z "$ARCHIVE" ]; then
  echo "Usage: ./unpack-migration.sh <archive.tar.gz>"
  exit 1
fi

echo "=== macOS Migration Unpack Script ==="
echo "Archive: $ARCHIVE"
echo ""

mkdir -p "$RESTORE_DIR"
tar -xzf "$ARCHIVE" -C "$RESTORE_DIR"
echo "Extracted to: $RESTORE_DIR"

echo ""
echo "=== RESTORING CONFIGS ==="

echo "[1] Shell configs..."
cp "$RESTORE_DIR/configs/."zsh* ~ 2>/dev/null || true
cp "$RESTORE_DIR/configs/.bash_profile" ~ 2>/dev/null || true
cp "$RESTORE_DIR/configs/.profile" ~ 2>/dev/null || true
cp "$RESTORE_DIR/configs/.gitconfig" ~ 2>/dev/null || true
cp "$RESTORE_DIR/configs/.npmrc" ~ 2>/dev/null || true

echo "[2] SSH keys..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh
cp "$RESTORE_DIR/ssh/"* ~/.ssh/ 2>/dev/null || true
chmod 600 ~/.ssh/id_* 2>/dev/null || true
chmod 644 ~/.ssh/*.pub 2>/dev/null || true

echo "[3] Fonts..."
cp "$RESTORE_DIR/fonts/"* ~/Library/Fonts/ 2>/dev/null || true

echo "[4] iTerm2 config..."
cp "$RESTORE_DIR/app-configs/com.googlecode.iterm2.plist" ~/Library/Preferences/ 2>/dev/null || true

echo "[5] Editor configs..."
mkdir -p ~/Library/Application\ Support/Cursor/User
cp "$RESTORE_DIR/editors/cursor/"* ~/Library/Application\ Support/Cursor/User/ 2>/dev/null || true

mkdir -p ~/Library/Application\ Support/Code/User
cp "$RESTORE_DIR/editors/vscode/"* ~/Library/Application\ Support/Code/User/ 2>/dev/null || true

mkdir -p ~/.config/zed
cp "$RESTORE_DIR/editors/zed/"* ~/.config/zed/ 2>/dev/null || true

echo "[6] App configs..."
mkdir -p ~/.config/gh
cp "$RESTORE_DIR/app-configs/config.yml" ~/.config/gh/ 2>/dev/null || true

cp -R "$RESTORE_DIR/app-configs/opencode" ~/.config/ 2>/dev/null || true
cp -R "$RESTORE_DIR/app-configs/solana" ~/.config/ 2>/dev/null || true
cp -R "$RESTORE_DIR/app-configs/claude-skills" ~/.claude/skills 2>/dev/null || true

mkdir -p ~/.local/bin
cp "$RESTORE_DIR/app-configs/local-bin-env" ~/.local/bin/env 2>/dev/null || true

echo "[7] Database dumps..."
for dump in "$RESTORE_DIR/databases/"*.sql; do
  [ -f "$dump" ] || continue
  dbname=$(basename "$dump" .sql)
  echo "  Restoring: $dbname"
  psql -d postgres -c "CREATE DATABASE $dbname;" 2>/dev/null || true
  psql -d "$dbname" -f "$dump" 2>/dev/null || echo "  (skipped - may need manual restore)"
done

echo ""
echo "=== RESTORE COMPLETE ==="
echo ""
echo "MANUAL STEPS REQUIRED:"
echo ""
echo "1. Install Homebrew:"
echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
echo ""
echo "2. Install packages:"
echo "   brew bundle install --file=$RESTORE_DIR/Brewfile"
echo ""
echo "3. Install Node (NVM):"
echo "   source /opt/homebrew/opt/nvm/nvm.sh"
echo "   nvm install \$(cat $RESTORE_DIR/nvm-version.txt)"
echo ""
echo "4. Install Rust:"
echo "   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
echo ""
echo "5. Install Cursor extensions:"
echo "   xargs -n1 cursor --install-extension < $RESTORE_DIR/editors/cursor-extensions.txt"
echo ""
echo "6. Login to apps:"
echo "   - 1Password"
echo "   - Raycast"
echo "   - Docker Desktop / OrbStack"
echo ""
echo "7. Add SSH keys to agent:"
echo "   ssh-add ~/.ssh/id_ed25519_*"
echo ""
echo "8. Restart shell:"
echo "   exec zsh"
