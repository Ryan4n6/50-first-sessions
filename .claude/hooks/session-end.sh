#!/usr/bin/env bash
# session-end.sh — Auto-persist memory files on session end
# Called by Claude Code SessionEnd hook
# Commits any changes to .claude/memory/ so context survives across sessions
#
# Part of 50-first-sessions: https://github.com/Ryan4n6/50-first-sessions

set -euo pipefail

# Navigate to repo root (works from worktrees too)
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

# ============================================================
# WORKTREE SAFETY: If we're in a worktree, commit memory files
# to the worktree branch but NEVER delete the worktree or branch.
# Cleanup happens from main repo or next session.
# ============================================================
IN_WORKTREE=false
GIT_DIR="$(git rev-parse --git-dir 2>/dev/null || echo "")"
GIT_COMMON="$(git rev-parse --git-common-dir 2>/dev/null || echo "")"
if [ -n "$GIT_DIR" ] && [ -n "$GIT_COMMON" ] && [ "$GIT_DIR" != "$GIT_COMMON" ]; then
    IN_WORKTREE=true
fi

# Stage memory files if they changed
git add .claude/memory/ 2>/dev/null || true

# Check if there's anything to commit
if ! git diff --cached --quiet 2>/dev/null; then
    BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
    CHANGED=$(git diff --cached --name-only | wc -l | tr -d ' ')
    CHANGED_FILES=$(git diff --cached --name-only | sed 's|.claude/memory/||' | tr '\n' ', ' | sed 's/,$//')

    # Quick secret scan before committing
    SECRETS_FOUND=$(git diff --cached --diff-filter=AM -- .claude/memory/ 2>/dev/null | \
        grep -iE '(api[_-]?key|secret[_-]?key|token|password|credential|private[_-]?key)\s*[:=]' | \
        grep -vE '(example|placeholder|your-|TODO|CHANGEME|xxx|template)' || true)

    if [ -n "$SECRETS_FOUND" ]; then
        echo "WARNING: Possible secrets detected in memory files. Skipping auto-commit."
        echo "Review staged changes with: git diff --cached .claude/memory/"
        git reset HEAD .claude/memory/ 2>/dev/null || true
    else
        git commit -m "memory($BRANCH): update $CHANGED_FILES" --no-verify 2>/dev/null || true
        echo "Auto-committed $CHANGED memory file(s)."
    fi
else
    echo "No memory file changes to persist."
fi

if [ "$IN_WORKTREE" = true ]; then
    echo "Session ended in worktree. Branch and worktree left intact."
    echo "To clean up, run from main repo: git worktree remove <path> && git branch -d <branch>"
fi
