#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIGS_DIR="$SCRIPT_DIR/configs"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

info()  { printf "\033[1;34m[INFO]\033[0m  %s\n" "$1"; }
ok()    { printf "\033[1;32m[OK]\033[0m    %s\n" "$1"; }
warn()  { printf "\033[1;33m[WARN]\033[0m  %s\n" "$1"; }

backup_if_exists() {
  local target="$1"
  if [ -f "$target" ]; then
    local backup="${target}.backup.${TIMESTAMP}"
    cp "$target" "$backup"
    warn "Backed up $target -> $backup"
  fi
}

# ─── Step 1: Homebrew ────────────────────────────────────────────────────────
info "Checking Homebrew..."
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  ok "Homebrew already installed"
fi

# ─── Step 2: Homebrew Packages ───────────────────────────────────────────────
info "Installing Homebrew packages..."

install_formula() {
  if brew list "$1" &>/dev/null; then
    ok "$1 already installed"
  else
    info "Installing $1..."
    brew install "$1"
  fi
}

install_cask() {
  if brew list --cask "$1" &>/dev/null; then
    ok "$1 (cask) already installed"
  else
    info "Installing $1 (cask)..."
    brew install --cask "$1"
  fi
}

install_formula "starship"
install_formula "tmux"
install_formula "neofetch"
install_cask "font-fira-code-nerd-font"

# ─── Step 3: Starship ────────────────────────────────────────────────────────
info "Setting up Starship..."
mkdir -p "$HOME/.config"
backup_if_exists "$HOME/.config/starship.toml"
starship preset nerd-font-symbols -o "$HOME/.config/starship.toml"
ok "Starship nerd-font-symbols preset applied"

if grep -q 'starship init zsh' "$HOME/.zshrc" 2>/dev/null; then
  ok "Starship init already in ~/.zshrc"
else
  echo '' >> "$HOME/.zshrc"
  echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
  ok "Added Starship init to ~/.zshrc"
fi

# ─── Step 4: Tmux + TPM ──────────────────────────────────────────────────────
info "Setting up Tmux..."
mkdir -p "$HOME/.config/tmux"
backup_if_exists "$HOME/.config/tmux/tmux.conf"
cp "$CONFIGS_DIR/tmux.conf" "$HOME/.config/tmux/tmux.conf"
ok "Copied tmux.conf -> ~/.config/tmux/tmux.conf"

if [ -d "$HOME/.tmux/plugins/tpm" ]; then
  ok "TPM already cloned"
else
  info "Cloning TPM..."
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

info "Installing tmux plugins..."
"$HOME/.tmux/plugins/tpm/bin/install_plugins"
ok "Tmux plugins installed"

# ─── Step 5: Neofetch ────────────────────────────────────────────────────────
info "Setting up Neofetch..."
mkdir -p "$HOME/.config/neofetch"
backup_if_exists "$HOME/.config/neofetch/config.conf"
cp "$CONFIGS_DIR/neofetch.conf" "$HOME/.config/neofetch/config.conf"
cp "$CONFIGS_DIR/neofetch-ascii.txt" "$HOME/.config/neofetch/custom-ascii.txt"
ok "Neofetch config and custom ASCII art applied"

# ─── Step 6: Terminal Profile ────────────────────────────────────────────────
TERMINAL_PROFILE="$CONFIGS_DIR/SanjiBasic.terminal"
PROFILE_NAME="Basic"

info "Importing Terminal profile..."
open "$TERMINAL_PROFILE"
sleep 1

osascript <<EOF
tell application "Terminal"
  set default settings to settings set "$PROFILE_NAME"
  -- close the window opened by the import
  set allWindows to id of every window
  repeat with wID in allWindows
    try
      close (every window whose id is wID)
    end try
  end repeat
end tell
EOF

defaults write com.apple.Terminal "Startup Window Settings" -string "$PROFILE_NAME"
ok "Terminal profile '$PROFILE_NAME' imported and set as default"

# ─── Step 7: Summary ─────────────────────────────────────────────────────────
echo ""
printf "\033[1;32m✔ Terminal setup complete!\033[0m\n"
echo ""
echo "Post-setup steps:"
echo "  1. Run: source ~/.zshrc"
echo "  2. Open tmux and verify prefix (Ctrl-a) works"
echo "  3. Run: neofetch"
echo ""
