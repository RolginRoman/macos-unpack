#!/bin/bash
set -e

BACKUP_DIR="$HOME/migration-backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="macos-migration-$TIMESTAMP"

echo "=== macOS Migration Pack Script ==="
echo "Creating backup in: $BACKUP_DIR"
rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

mkdir -p "$BACKUP_DIR/macos-defaults"
mkdir -p "$BACKUP_DIR/recommended"

echo ""

echo "[1/16] Packing shell configs..."
mkdir -p "$BACKUP_DIR/configs"
# Zsh configs
cp -L ~/.zshrc "$BACKUP_DIR/configs/" 2>/dev/null || true
cp -L ~/.zshenv "$BACKUP_DIR/configs/" 2>/dev/null || true
cp -L ~/.zsh_history "$BACKUP_DIR/configs/" 2>/dev/null || true
# Bash configs & aliases
cp -L ~/.bashrc "$BACKUP_DIR/configs/" 2>/dev/null || true
cp -L ~/.bash_profile "$BACKUP_DIR/configs/" 2>/dev/null || true
cp -L ~/.bash_history "$BACKUP_DIR/configs/" 2>/dev/null || true
cp -L ~/.bash_aliases "$BACKUP_DIR/configs/" 2>/dev/null || true
cp -L ~/.bash_completion "$BACKUP_DIR/configs/" 2>/dev/null || true
# Other shell configs
cp -L ~/.profile "$BACKUP_DIR/configs/" 2>/dev/null || true
cp -L ~/.inputrc "$BACKUP_DIR/configs/" 2>/dev/null || true
cp -L ~/.gitconfig "$BACKUP_DIR/configs/" 2>/dev/null || true
cp -L ~/.npmrc "$BACKUP_DIR/configs/" 2>/dev/null || true

echo "[2/16] Packing SSH keys..."
mkdir -p "$BACKUP_DIR/ssh"
cp -L ~/.ssh/config "$BACKUP_DIR/ssh/" 2>/dev/null || true
cp -L ~/.ssh/id_* "$BACKUP_DIR/ssh/" 2>/dev/null || true
cp -L ~/.ssh/known_hosts "$BACKUP_DIR/ssh/" 2>/dev/null || true

echo "[3/16] Packing Homebrew packages list..."
DEPRECATED_FORMULAS="openssl@1.1|openssl@1|python@3.9|python@3.8|node@14|node@16"
brew bundle dump --file="$BACKUP_DIR/Brewfile" --force 2>/dev/null || echo "Homebrew not found, skipping"
if [[ -f "$BACKUP_DIR/Brewfile" ]]; then
  grep -Ev "^brew \"($DEPRECATED_FORMULAS)\"" "$BACKUP_DIR/Brewfile" > "$BACKUP_DIR/Brewfile.tmp" && mv "$BACKUP_DIR/Brewfile.tmp" "$BACKUP_DIR/Brewfile"
fi

echo "[4/16] Packing fnm & node version info..."
fnm current > "$BACKUP_DIR/fnm-node-version.txt" 2>/dev/null || fnm ls-remote --lts | head -1 | awk '{print $2}' > "$BACKUP_DIR/fnm-node-version.txt" 2>/dev/null || echo "lts" > "$BACKUP_DIR/fnm-node-version.txt"
npm list -g --depth=0 > "$BACKUP_DIR/npm-global-packages.txt" 2>/dev/null || true

echo "[5/16] Packing Rust toolchain info..."
rustup show > "$BACKUP_DIR/rust-toolchains.txt" 2>/dev/null || true
cargo install --list > "$BACKUP_DIR/cargo-installed.txt" 2>/dev/null || true

echo "[6/16] Packing Python packages..."
uv pip list > "$BACKUP_DIR/uv-packages.txt" 2>/dev/null || pip3 list > "$BACKUP_DIR/pip-packages.txt" 2>/dev/null || true

echo "[7/16] Packing Go tools..."
ls -la ~/go/bin/ > "$BACKUP_DIR/go-tools.txt" 2>/dev/null || true

echo "[8/16] Packing editor configs..."
mkdir -p "$BACKUP_DIR/editors"
mkdir -p "$BACKUP_DIR/editors/cursor"
cp -RL ~/Library/Application\ Support/Cursor/User/settings.json "$BACKUP_DIR/editors/cursor/" 2>/dev/null || true
cp -RL ~/Library/Application\ Support/Cursor/User/keybindings.json "$BACKUP_DIR/editors/cursor/" 2>/dev/null || true
cp -RL ~/Library/Application\ Support/Cursor/User/tasks.json "$BACKUP_DIR/editors/cursor/" 2>/dev/null || true
cursor --list-extensions > "$BACKUP_DIR/editors/cursor-extensions.txt" 2>/dev/null || true
mkdir -p "$BACKUP_DIR/editors/vscode"
cp -RL ~/Library/Application\ Support/Code/User/settings.json "$BACKUP_DIR/editors/vscode/" 2>/dev/null || true
mkdir -p "$BACKUP_DIR/editors/zed"
cp -RL ~/.config/zed/settings.json "$BACKUP_DIR/editors/zed/" 2>/dev/null || true

echo "[9/16] Packing Internet Accounts..."
mkdir -p "$BACKUP_DIR/internet-accounts"
cp -RL ~/Library/Accounts/* "$BACKUP_DIR/internet-accounts/" 2>/dev/null || true

echo "[10/16] Packing app configs..."
mkdir -p "$BACKUP_DIR/app-configs"
cp -RL ~/.config/gh/config.yml "$BACKUP_DIR/app-configs/gh-config.yml" 2>/dev/null || true
cp -RL ~/.config/opencode "$BACKUP_DIR/app-configs/opencode" 2>/dev/null || true
cp -RL ~/.config/solana "$BACKUP_DIR/app-configs/solana" 2>/dev/null || true
cp -RL ~/.claude/skills "$BACKUP_DIR/app-configs/claude-skills" 2>/dev/null || true
cp -RL ~/.local/bin/env "$BACKUP_DIR/app-configs/local-bin-env" 2>/dev/null || true

echo "[11/16] Packing fonts..."
mkdir -p "$BACKUP_DIR/fonts"
cp -RL ~/Library/Fonts/* "$BACKUP_DIR/fonts/" 2>/dev/null || true

echo "[12/16] Packing OrbStack/Docker info..."
docker images --format "{{.Repository}}:{{.Tag}}" > "$BACKUP_DIR/docker-images.txt" 2>/dev/null || true
docker volume ls --format "{{.Name}}" > "$BACKUP_DIR/docker-volumes.txt" 2>/dev/null || true

echo "[13/16] Packing database dumps..."
mkdir -p "$BACKUP_DIR/databases"
for db in $(psql -lqt 2>/dev/null | cut -d \| -f 1 | tr -d ' ' | grep -v template | grep -v postgres); do
  echo "  Dumping: $db"
  pg_dump "$db" > "$BACKUP_DIR/databases/${db}.sql" 2>/dev/null || true
done

echo "[14/16] Packing macOS defaults..."
defaults read com.apple.dock | grep -E "(autohide|minimize-to-application|mru-spaces)" > "$BACKUP_DIR/macos-defaults/dock.txt" 2>/dev/null || true
defaults read com.apple.finder | grep -E "(AppleShowAllFiles|AppleShowAllExtensions|ShowPathbar|ShowStatusBar)" > "$BACKUP_DIR/macos-defaults/finder.txt" 2>/dev/null || true
defaults read NSGlobalDomain | grep -E "(AppleKeyboardUIMode|AppleMeasurementUnits|AppleLocale|AppleShowScrollBars)" > "$BACKUP_DIR/macos-defaults/global.txt" 2>/dev/null || true
defaults read com.apple.screensaver | grep -E "(idleTime|askForPassword)" > "$BACKUP_DIR/macos-defaults/screensaver.txt" 2>/dev/null || true

echo "[15/16] Saving recommended packages list..."
cat > "$BACKUP_DIR/recommended/packages.txt" << 'EOF'
# Core utilities
coreutils
moreutils
findutils
gnu-sed
wget
curl

# Search & code tools
ripgrep
the_silver_searcher
fzf
tree
jq
yq

# Git & GitHub
git
git-lfs
gh
diff-so-fancy
tig

# Shell & prompt
starship
zoxide
zsh-autosuggestions
zsh-fast-syntax-highlighting
direnv
tmux
shellcheck
shfmt

# Development
watchman
eza
 entr
parallel
ffmpeg

# Languages & runtimes
python@3.11
go
node
rust

# Package managers
pnpm
bun
pipx

# DevOps
orbstack
docker-completion
podman

# Fonts (casks)
font-meslo-lg-nerd-font

# GUI apps (casks)
iterm2
orbstack
tailscale
betterdisplay
aldente
raycast
1password
claude
obsidian
cursor
zed
visual-studio-code
shottr
appcleaner
vlc
EOF

echo "  Saved recommended packages list"

echo "[16/16] Creating archive..."
cd "$HOME"
tar -czvf "${ARCHIVE_NAME}.tar.gz" -C "$BACKUP_DIR" .

SIZE=$(du -h "${ARCHIVE_NAME}.tar.gz" | cut -f1)

echo ""
echo "=== PACK COMPLETE ==="
echo "Archive: $HOME/${ARCHIVE_NAME}.tar.gz"
echo "Size: $SIZE"
echo "Contents: $BACKUP_DIR"
echo ""
echo "Transfer to new machine via:"
echo "  - AirDrop"
echo "  - scp user@old-machine:~/${ARCHIVE_NAME}.tar.gz ."
echo "  - Cloud storage"
echo "  - USB drive"
