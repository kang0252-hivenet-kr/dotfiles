# install.ps1 - Apply these dotfiles on this machine (Windows, PowerShell).
# Copy-based (no symbolic link / admin rights required).
#
# Usage:  cd ~/dotfiles ; ./install.ps1
#
# NOTE: The statusline command in settings.json references
#       ~/dotfiles/.claude/statusline-command.sh directly, so this repo MUST be
#       cloned to  $HOME\dotfiles  for the path to resolve.

$ErrorActionPreference = "Stop"
$repo      = Split-Path -Parent $MyInvocation.MyCommand.Path
$claudeDir = Join-Path $env:USERPROFILE ".claude"

if ((Resolve-Path $repo).Path -ne (Join-Path $env:USERPROFILE "dotfiles")) {
    Write-Warning "This repo is not at $env:USERPROFILE\dotfiles. The statusline path in settings.json expects ~/dotfiles. Clone it there or edit the command path."
}

New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null

# Back up an existing settings.json once, then install ours.
$target = Join-Path $claudeDir "settings.json"
if ((Test-Path $target) -and -not (Test-Path "$target.bak")) {
    Copy-Item $target "$target.bak"
    Write-Host "Backed up existing settings.json -> settings.json.bak"
}
Copy-Item (Join-Path $repo ".claude\settings.json") $target -Force
Write-Host "Installed settings.json -> $claudeDir"
Write-Host "Statusline script is referenced from the repo directly (no copy needed)."
Write-Host "Done. Restart Claude Code to pick up the status line."
