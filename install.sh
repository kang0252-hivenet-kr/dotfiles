#!/usr/bin/env bash
# install.sh - Apply these dotfiles on this machine (Git Bash / macOS / Linux).
# Copy-based (no symbolic link required).
#
# Usage:  cd ~/dotfiles && bash install.sh
#
# NOTE: The statusline command in settings.json references
#       ~/dotfiles/.claude/statusline-command.sh directly, so this repo MUST be
#       cloned to  $HOME/dotfiles  for the path to resolve.
set -e

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
claude="$HOME/.claude"

if [ "$repo" != "$HOME/dotfiles" ]; then
  echo "WARNING: repo is at '$repo', not '$HOME/dotfiles'. The statusline path in" >&2
  echo "         settings.json expects ~/dotfiles. Clone it there or edit the path." >&2
fi

mkdir -p "$claude"

target="$claude/settings.json"
if [ -f "$target" ] && [ ! -f "$target.bak" ]; then
  cp "$target" "$target.bak"
  echo "Backed up existing settings.json -> settings.json.bak"
fi

cp "$repo/.claude/settings.json" "$target"
echo "Installed settings.json -> $claude"
echo "Statusline script is referenced from the repo directly (no copy needed)."
echo "Done. Restart Claude Code to pick up the status line."
