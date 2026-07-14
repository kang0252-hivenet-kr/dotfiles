# dotfiles

Personal config synced across machines. Currently manages the **Claude Code** user
settings and status line.

```
.claude/
  settings.json           # Claude Code user settings (theme, tui, statusLine, ...)
  statusline-command.sh   # Status line renderer: model | dir (branch) | tokens | cost | 5h/7d
install.ps1               # Apply on Windows (PowerShell)
install.sh                # Apply on Git Bash / macOS / Linux
```

## Status line

Shows, with progress bars, in the Claude Code bottom bar:

```
Opus 4.8 (1M context) | MacroScheduler (master) | Ctx [░░░░░░░░░░] 4% (40K/1M) | $0.49 | 5h [███░░░░░░░] 28%(->13:40)  7d [██░░░░░░░░] 21%
```

- **Ctx** — context/token usage (used % + used/total tokens)
- **$** — session cost so far
- **5h / 7d** — Claude.ai (Pro/Max) rate-limit windows; only shown for subscribers

The renderer parses the status line JSON with **python3** (not `jq`). Requirements on
any machine: **Git Bash** (the command runs via `bash`) and **python** on `PATH`.

## Set up on a NEW machine

```sh
# 1. Clone to ~/dotfiles  (the path matters — see note below)
git clone <your-repo-url> ~/dotfiles

# 2. Install
#    Windows PowerShell:
cd ~/dotfiles ; ./install.ps1
#    Git Bash / macOS / Linux:
cd ~/dotfiles && bash install.sh

# 3. Restart Claude Code.
```

> The `statusLine.command` in `settings.json` points at
> `~/dotfiles/.claude/statusline-command.sh`, so the repo **must live at `~/dotfiles`**.
> Cloning elsewhere means editing that path in `.claude/settings.json`.

## Save local changes back (this machine is the source of truth)

The status line script is edited **in place** in this repo (it is referenced directly,
not copied), so just commit:

```sh
cd ~/dotfiles
git add -A
git commit -m "Update status line"
git push
```

If you changed `~/.claude/settings.json` directly instead, copy it back first:

```sh
cp ~/.claude/settings.json ~/dotfiles/.claude/settings.json
```
