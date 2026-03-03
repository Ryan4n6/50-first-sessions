#!/usr/bin/env bash
# watch-session.sh — Launch a monitored Claude Code session
#
# Creates a tmux session with 3 panes:
#   1. Claude Code executor (main pane — where the action happens)
#   2. Git activity monitor (commits, status, diffs in real-time)
#   3. Test watcher (watches for test runs and results)
#
# Usage:
#   bash watch-session.sh                    # Run in current directory
#   bash watch-session.sh /path/to/project   # Run in specific project
#   bash watch-session.sh --plan docs/plans/my-plan.md  # Auto-start a plan
#
# To watch from another terminal:
#   tmux attach -t claude-watch
#
# Pane navigation:
#   Ctrl+B, arrow keys  — switch between panes
#   Ctrl+B, z           — zoom/unzoom current pane (fullscreen toggle)
#   Ctrl+B, d           — detach (session keeps running in background)

set -euo pipefail

SESSION="claude-watch"
PROJECT_DIR="${1:-.}"
PLAN_FILE=""

# Parse --plan flag
if [ "${1:-}" = "--plan" ]; then
    PLAN_FILE="${2:?Usage: watch-session.sh --plan <plan-file>}"
    PROJECT_DIR="."
elif [ "${2:-}" = "--plan" ]; then
    PLAN_FILE="${3:?Usage: watch-session.sh [dir] --plan <plan-file>}"
fi

# Resolve to absolute path
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

# Kill existing session if running
tmux kill-session -t "$SESSION" 2>/dev/null || true

# ─── Create the layout ─────────────────────────────────────
#
#  ┌──────────────────────────────────┐
#  │                                  │
#  │     Claude Code (executor)       │
#  │          70% height              │
#  │                                  │
#  ├─────────────────┬────────────────┤
#  │  Git Monitor    │  Test Watcher  │
#  │    30% height   │   30% height   │
#  └─────────────────┴────────────────┘

# Main pane: Claude Code
tmux new-session -d -s "$SESSION" -c "$PROJECT_DIR" \
  -x "$(tput cols)" -y "$(tput lines)"

# Split bottom 30% for monitors
tmux split-window -t "$SESSION" -v -p 30 -c "$PROJECT_DIR"

# Split bottom row into two panes
tmux split-window -t "$SESSION" -h -p 50 -c "$PROJECT_DIR"

# ─── Pane 0 (top): Claude Code executor ────────────────────
if [ -n "$PLAN_FILE" ]; then
    tmux send-keys -t "${SESSION}:0.0" \
      "echo '=== Claude Code Executor ===' && echo 'Plan: $PLAN_FILE' && echo '' && claude --dangerously-skip-permissions" Enter
else
    tmux send-keys -t "${SESSION}:0.0" \
      "echo '=== Claude Code Executor ===' && claude --dangerously-skip-permissions" Enter
fi

# ─── Pane 1 (bottom-left): Git activity monitor ────────────
tmux send-keys -t "${SESSION}:0.1" \
  "echo '=== Git Monitor ===' && watch -n 3 -c 'echo \"--- Recent Commits ---\" && git log --oneline --color=always -8 && echo \"\" && echo \"--- Working Tree ---\" && git status --short && echo \"\" && echo \"--- Uncommitted Changes ---\" && git diff --stat 2>/dev/null'" Enter

# ─── Pane 2 (bottom-right): File watcher ───────────────────
tmux send-keys -t "${SESSION}:0.2" \
  "echo '=== File Watcher ===' && watch -n 5 -c 'echo \"--- Recently Modified ---\" && find . -name \"*.py\" -newer .git/HEAD -not -path \"./.venv/*\" -not -path \"./.claude/*\" 2>/dev/null | head -20 && echo \"\" && echo \"--- Test Files ---\" && find . -name \"test_*.py\" -newer .git/HEAD -not -path \"./.venv/*\" 2>/dev/null | head -10'" Enter

# ─── Select the main pane ───────────────────────────────────
tmux select-pane -t "${SESSION}:0.0"

echo ""
echo "Session '$SESSION' is running."
echo ""
echo "  To watch:   tmux attach -t $SESSION"
echo "  To detach:  Ctrl+B, then D"
echo "  Zoom pane:  Ctrl+B, then Z"
echo "  Switch:     Ctrl+B, then arrow keys"
echo ""

# Attach to the session
tmux attach -t "$SESSION"
