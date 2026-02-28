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

# ─── Step 3: Shell Configs ───────────────────────────────────────────────────
info "Setting up shell configs..."

backup_if_exists "$HOME/.zshrc"
cp "$CONFIGS_DIR/zshrc" "$HOME/.zshrc"
ok "Copied zshrc -> ~/.zshrc"

backup_if_exists "$HOME/.zprofile"
cp "$CONFIGS_DIR/zprofile" "$HOME/.zprofile"
ok "Copied zprofile -> ~/.zprofile"

# Auto-detect Netskope MDM cert and uncomment SSL exports
NETSKOPE_CERT="/Library/Application Support/ns_cert/nscacert_combined.pem"
if [ -f "$NETSKOPE_CERT" ]; then
  info "Netskope MDM cert detected — enabling SSL exports in .zshrc"
  sed -i '' '/^# --- Corporate: Netskope MDM ---$/,/^$/{
    s/^# \(export [A-Z_]*BUNDLE=\)/\1/
    s/^# \(export SSL_CERT_FILE=\)/\1/
    s/^# \(export GIT_SSL_CAPATH=\)/\1/
    s/^# \(export NODE_EXTRA_CA_CERTS=\)/\1/
  }' "$HOME/.zshrc"
  ok "Netskope SSL exports uncommented"
else
  ok "No Netskope cert found — SSL exports left commented"
fi

# ─── Step 4: Starship ────────────────────────────────────────────────────────
info "Setting up Starship config..."
mkdir -p "$HOME/.config"
backup_if_exists "$HOME/.config/starship.toml"
starship preset nerd-font-symbols -o "$HOME/.config/starship.toml"
ok "Starship nerd-font-symbols preset applied"

# ─── Step 5: Tmux + TPM ─────────────────────────────────────────────────────
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

# ─── Step 6: Neofetch ────────────────────────────────────────────────────────
info "Neofetch setup..."
ok "Neofetch installed — default config will auto-generate on first run"

# ─── Step 7: Summary ────────────────────────────────────────────────────────
echo ""
printf "\033[1;32m✔ Terminal setup complete!\033[0m\n"
echo ""
echo "Post-setup steps:"
echo "  1. Set your terminal font to 'FiraCode Nerd Font' (or any Nerd Font)"
echo "  2. Run: source ~/.zshrc"
echo "  3. Open tmux and verify prefix (Ctrl-a) works"
echo "  4. Run: neofetch"
echo ""
echo "Optional:"
echo "  • Uncomment work aliases in ~/.zshrc if on a work machine"
echo ""
