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

Shell configs (`.zshrc`, `.zprofile`) are copied from this repo.

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

## Config Details

### Shell Configs
- **`.zshrc`** — Starship init, pyenv, pnpm, editor, PATH entries
- **`.zprofile`** — Homebrew shellenv, Go PATH

### Work-Specific (Commented Out)
The `.zshrc` includes commented-out blocks for:
- **Atlan work aliases** (`patlan`, `vcluster`, `argopm`)
- **Heracles Go env vars** (`GO111MODULE`, `GOPRIVATE`)

Uncomment these on work machines as needed.

### Corporate MDM (Auto-Detected)
If a Netskope MDM certificate is detected at `/Library/Application Support/ns_cert/nscacert_combined.pem`, the script automatically uncomments the SSL certificate exports in `.zshrc`.

## Backups

Existing configs are backed up before overwriting:
```
~/.zshrc                    -> ~/.zshrc.backup.20260228_143000
~/.zprofile                 -> ~/.zprofile.backup.20260228_143000
~/.config/starship.toml     -> ~/.config/starship.toml.backup.20260228_143000
~/.config/tmux/tmux.conf    -> ~/.config/tmux/tmux.conf.backup.20260228_143000
```
