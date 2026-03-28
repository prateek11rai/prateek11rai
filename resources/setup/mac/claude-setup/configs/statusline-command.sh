#!/usr/bin/env bash
# Claude Code statusLine command
# Mirrors the Starship default prompt: user@host  dir  git_branch | model  context%

input=$(cat)

user=$(whoami)
host=$(hostname -s)
dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
# Show ~ for home directory prefix
home_dir="$HOME"
display_dir="${dir/#$home_dir/\~}"

model=$(echo "$input" | jq -r '.model.display_name // ""')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')

# Git branch (skip optional locks to avoid blocking)
git_branch=""
if [ -d "$dir/.git" ] || git -C "$dir" rev-parse --git-dir >/dev/null 2>&1; then
  git_branch=$(git -C "$dir" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
fi

# Build the status line with ANSI colors
# user@host in green, dir in blue, git branch in yellow, model in cyan, context in magenta
printf "\033[32m%s@%s\033[0m \033[34m%s\033[0m" "$user" "$host" "$display_dir"

if [ -n "$git_branch" ]; then
  printf "  \033[33m %s\033[0m" "$git_branch"
fi

if [ -n "$model" ]; then
  printf "  \033[36m%s\033[0m" "$model"
fi

if [ -n "$remaining" ]; then
  printf "  \033[35mctx: %s%%\033[0m" "$remaining"
fi

printf "\n"
