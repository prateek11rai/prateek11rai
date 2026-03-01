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
info "Neofetch setup..."
ok "Neofetch installed — default config will auto-generate on first run"

# ─── Step 6: Summary ─────────────────────────────────────────────────────────
echo ""
printf "\033[1;32m✔ Terminal setup complete!\033[0m\n"
echo ""
echo "Post-setup steps:"
echo "  1. Set your terminal font to 'FiraCode Nerd Font' (or any Nerd Font)"
echo "  2. Run: source ~/.zshrc"
echo "  3. Open tmux and verify prefix (Ctrl-a) works"
echo "  4. Run: neofetch"
echo ""
