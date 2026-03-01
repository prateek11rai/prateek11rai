# Mac Terminal Setup

One-script setup for a fully configured Mac terminal environment.

## What Gets Installed

| Tool | Source | Config |
|------|--------|--------|
| **Homebrew** | Official installer | — |
| **Starship** | `brew install starship` | Nerd Font Symbols preset (generated via `starship preset`) |
| **Tmux** | `brew install tmux` | Custom config (Ctrl-a prefix, mouse, TPM plugins) |
| **Neofetch** | `brew install neofetch` | Default (auto-generated on first run) |
| **FiraCode Nerd Font** | `brew install --cask font-fira-code-nerd-font` | — |

Starship shell init is appended to `~/.zshrc` if not already present. Homebrew handles `.zprofile` automatically.

## Prerequisites

- macOS (Apple Silicon or Intel)
- Git (pre-installed on macOS)
- Internet connection (for Homebrew and git clones)

## Usage

```bash
git clone https://github.com/prateek11rai/prateek11rai.git
cd prateek11rai
bash resources/setup/mac/terminal-setup/setup.sh
```

The script is **idempotent** — safe to re-run. It skips already-installed packages and backs up existing configs with a timestamp before overwriting.

## Post-Setup

1. **Set terminal font** — Open your terminal settings and set the font to `FiraCode Nerd Font` (required for Starship symbols)
2. **Reload shell** — `source ~/.zshrc`
3. **Verify tmux** — Open `tmux`, confirm `Ctrl-a` is the prefix
4. **Run neofetch** — Should display system info

## Corporate MDM (Manual)

On corporate laptops with Netskope MDM, manually add the following SSL certificate exports to `~/.zshrc`:

```bash
export AWS_CA_BUNDLE="/Library/Application Support/ns_cert/nscacert_combined.pem"
export CURL_CA_BUNDLE="/Library/Application Support/ns_cert/nscacert_combined.pem"
export SSL_CERT_FILE="/Library/Application Support/ns_cert/nscacert_combined.pem"
export GIT_SSL_CAPATH="/Library/Application Support/ns_cert/nscacert_combined.pem"
export REQUESTS_CA_BUNDLE="/Library/Application Support/ns_cert/nscacert_combined.pem"
export NODE_EXTRA_CA_CERTS="/Library/Application Support/ns_cert/nscacert_combined.pem"
```

## Backups

Existing configs are backed up before overwriting:
```
~/.config/starship.toml     -> ~/.config/starship.toml.backup.20260228_143000
~/.config/tmux/tmux.conf    -> ~/.config/tmux/tmux.conf.backup.20260228_143000
```
