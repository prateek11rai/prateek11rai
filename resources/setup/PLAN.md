# Mac Terminal Setup Migration Script

## Context
Create a reusable setup/migration script system so that any new Mac gets an identical terminal experience by cloning this repo and running a single script. Starting with Mac terminal setup; Windows and Linux will follow later.

## Folder Structure
```
resources/
  setup/
    mac/
      terminal-setup/
        setup.sh              # Main setup script
        README.md             # Documentation
        configs/
          zshrc               # -> ~/.zshrc
          zprofile            # -> ~/.zprofile
          tmux.conf           # -> ~/.config/tmux/tmux.conf
    windows/
      README.md               # Placeholder
    linux/
      README.md               # Placeholder
```

Minimal file copies — uses native tool commands where possible:
- **Starship**: `starship preset nerd-font-symbols` (current config is exactly this preset)
- **Neofetch**: `neofetch --print_config > config.conf` or just run neofetch (current config is 100% default, confirmed via md5 match)
- **Tmux config**: Must copy (custom prefix, plugins, mouse settings)
- **Shell configs**: Must copy (personalized aliases, PATH, etc.)

## Script Logic (`setup.sh`)

Idempotent, safe to re-run. Uses `set -euo pipefail`.

### Step 1: Check/Install Homebrew
- If `brew` not found, install via official installer
- Activate for current session with `eval "$(/opt/homebrew/bin/brew shellenv)"`

### Step 2: Install Homebrew Packages (terminal tools only)
- Formulae: `starship`, `tmux`
- Neofetch: install from archived Homebrew formula (`brew install neofetch` still works even though deprecated) — if that stops working in the future, can clone from `https://github.com/dylanaraps/neofetch` and install manually
- Cask: `font-fira-code-nerd-font` (required for Starship Nerd Font symbols)
- Each guarded by `brew list` check to skip if already installed

### Step 3: Shell Configs (.zshrc, .zprofile)
- Backup existing files with timestamp (e.g., `.zshrc.backup.20260228_143000`)
- Copy `configs/zshrc` -> `~/.zshrc`
- Copy `configs/zprofile` -> `~/.zprofile`
- Auto-detect Netskope MDM cert and uncomment SSL exports if present

### Step 4: Starship Config (via native preset command — no file copy)
- `mkdir -p ~/.config`
- Backup existing `~/.config/starship.toml` if present
- Run `starship preset nerd-font-symbols -o ~/.config/starship.toml`

### Step 5: Tmux + TPM + Plugins
- `mkdir -p ~/.config/tmux`
- Backup + copy `configs/tmux.conf` -> `~/.config/tmux/tmux.conf`
- Clone TPM to `~/.tmux/plugins/tpm` if not present
- Run `~/.tmux/plugins/tpm/bin/install_plugins` non-interactively (tmux doesn't need to be running)

### Step 6: Neofetch — no config copy needed
- Neofetch auto-generates default config on first run
- Current config is verified 100% default (md5 match)
- Just ensure neofetch is installed; config will be default automatically

### Step 7: Print Summary
- Success message with post-setup steps (set terminal font, source zshrc, verify)

## Config File Changes from Current

### `configs/zshrc` (based on current `~/.zshrc`)
| Change | Why |
|--------|-----|
| `PNPM_HOME="/Users/prateek.rai/Library/pnpm"` -> `PNPM_HOME="$HOME/Library/pnpm"` | Make portable across usernames |
| `. "$HOME/.local/bin/env"` -> `[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"` | Guard against missing file on fresh system |
| Netskope SSL block -> commented out with `# --- Corporate: Netskope MDM ---` header | Corporate-specific; script auto-uncomments if cert detected |
| Work aliases (patlan, vcluster, argopm) -> commented out with `# --- Work: Atlan ---` header | Work-specific; easy to uncomment on work machines |
| Heracles Go env vars (GO111MODULE, GOPRIVATE) -> commented out under same work header | Work-specific |

### Other configs
- `zprofile` — exact copy, already portable
- `tmux.conf` — exact copy (27 lines), already portable (uses `~` paths)

## Files Created (7 total)

1. `resources/setup/mac/terminal-setup/setup.sh` — ~100 lines, main orchestrator
2. `resources/setup/mac/terminal-setup/README.md` — prerequisites, usage, what gets installed, post-setup
3. `resources/setup/mac/terminal-setup/configs/zshrc` — portable .zshrc with work entries commented out
4. `resources/setup/mac/terminal-setup/configs/zprofile` — exact copy of ~/.zprofile
5. `resources/setup/mac/terminal-setup/configs/tmux.conf` — exact copy of ~/.config/tmux/tmux.conf
6. `resources/setup/windows/README.md` — placeholder
7. `resources/setup/linux/README.md` — placeholder

## Verification
1. Run `bash resources/setup/mac/terminal-setup/setup.sh` on current machine (should skip installs, backup + copy configs)
2. Open new terminal — Starship prompt should render with Nerd Font symbols
3. Run `tmux` — prefix (Ctrl-a) should work, plugins loaded
4. Run `neofetch` — should display system info with default layout
