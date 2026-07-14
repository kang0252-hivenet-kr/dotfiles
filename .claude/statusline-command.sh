#!/bin/bash
#
# Claude Code status line
# Displays: model | cwd (git branch) | context/token usage | cost | 5h/7d rate-limit usage
#
# JSON is parsed with python3 (jq is NOT required / not installed on this machine).
# Fields consumed from the status line JSON on stdin:
#   .model.display_name / .model.id
#   .workspace.current_dir / .cwd
#   .context_window.used_percentage / .total_input_tokens / .context_window_size
#   .cost.total_cost_usd
#   .rate_limits.five_hour.used_percentage / .resets_at
#   .rate_limits.seven_day.used_percentage
#
# NOTE: rate_limits is only populated for Claude.ai subscribers (Pro/Max) and
# only after the session's first API response.

input=$(cat)

# Pick an available python
PY=$(command -v python || command -v python3)

# --- Parse everything in one python call -> tab-separated: model, cwd, ctx_str, cost_str, rate_str
parsed=$(printf '%s' "$input" | "$PY" -c '
import sys, json, datetime

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

try:
    d = json.load(sys.stdin)
except Exception:
    print("Claude\t\t\t\t")
    sys.exit(0)

def g(*keys, default=None):
    cur = d
    for k in keys:
        if isinstance(cur, dict) and cur.get(k) is not None:
            cur = cur[k]
        else:
            return default
    return cur

def bar(pct, width=10):
    pct = float(pct)
    filled = int(round(pct / 100 * width))
    filled = max(0, min(width, filled))
    return "█" * filled + "░" * (width - filled)

def human(n):
    try:
        n = int(n)
    except (TypeError, ValueError):
        return None
    if n >= 1_000_000:
        s = f"{n/1_000_000:.1f}M"
        return s.replace(".0M", "M")
    if n >= 1_000:
        return f"{n//1000}K"
    return str(n)

model = g("model", "display_name") or g("model", "id") or "Claude"
cwd   = g("workspace", "current_dir") or g("cwd") or ""

# --- context / token usage ---
ctx_pct = g("context_window", "used_percentage")
in_tok  = g("context_window", "total_input_tokens")
size    = g("context_window", "context_window_size")
ctx_str = ""
if ctx_pct is not None:
    pct = float(ctx_pct)
    ctx_str = f"Ctx [{bar(pct)}] {pct:.0f}%"
    ht, hs = human(in_tok), human(size)
    if ht and hs:
        ctx_str += f" ({ht}/{hs})"

# --- session cost ---
cost = g("cost", "total_cost_usd")
cost_str = f"${float(cost):.2f}" if cost is not None else ""

# --- 5h / 7d subscription windows ---
five  = g("rate_limits", "five_hour", "used_percentage")
freset = g("rate_limits", "five_hour", "resets_at")
week  = g("rate_limits", "seven_day", "used_percentage")
rate_bits = []
if five is not None:
    s = f"5h [{bar(five)}] {float(five):.0f}%"
    if freset is not None:
        try:
            s += "(->" + datetime.datetime.fromtimestamp(int(freset)).strftime("%H:%M") + ")"
        except Exception:
            pass
    rate_bits.append(s)
if week is not None:
    rate_bits.append(f"7d [{bar(week)}] {float(week):.0f}%")
rate_str = "  ".join(rate_bits)

print("\t".join([model, cwd, ctx_str, cost_str, rate_str]))
')

IFS=$'\t' read -r model cwd ctx_str cost_str rate_str <<< "$parsed"

# --- Working directory ---
[ -z "$cwd" ] && cwd="$PWD"
dir_name=$(basename "$cwd")

# --- Git branch (skip optional locks so this never blocks or writes lock files) ---
branch=""
if git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)
fi

# --- Assemble ---
line="$model | $dir_name"
[ -n "$branch" ]   && line="$line ($branch)"
[ -n "$ctx_str" ]  && line="$line | $ctx_str"
[ -n "$cost_str" ] && line="$line | $cost_str"
[ -n "$rate_str" ] && line="$line | $rate_str"

echo "$line"
