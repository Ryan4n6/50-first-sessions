#!/usr/bin/env bash
# session-start.sh — Auto-inject context on session start
# Called by Claude Code SessionStart hook (startup, resume, compact)
# stdout is injected into Claude's context automatically
#
# Part of 50-first-sessions: https://github.com/Ryan4n6/50-first-sessions

set -euo pipefail

# Navigate to repo root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

echo "=== SESSION CONTEXT ==="
echo ""

# Current branch
BRANCH=$(git branch --show-current 2>/dev/null || echo "detached")
echo "Branch: $BRANCH"
echo ""

# Recent commits
echo "Recent commits:"
git log --oneline -5 2>/dev/null || echo "  (no commits)"
echo ""

# Uncommitted changes summary
CHANGES=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [ "$CHANGES" -gt 0 ]; then
    echo "Uncommitted changes: $CHANGES files"
    git status --short 2>/dev/null | head -10
    echo ""
fi

# Memory file header (if exists)
if [ -f "$REPO_ROOT/.claude/memory/MEMORY.md" ]; then
    echo "Memory index (first 15 lines):"
    head -15 "$REPO_ROOT/.claude/memory/MEMORY.md" 2>/dev/null
    echo ""
fi

# Open issues (if gh CLI available)
if command -v gh &>/dev/null || [ -x /usr/local/bin/gh ]; then
    GH="${GH:-$(command -v gh 2>/dev/null || echo /usr/local/bin/gh)}"

    echo "Open issues (top 5):"
    $GH issue list --state open --limit 5 --json number,title,labels \
        --jq '.[] | "  #\(.number): \(.title)"' 2>/dev/null \
        || echo "  (gh not authenticated or no issues)"
    echo ""

    # If on a feature branch, inject the linked issue body
    ISSUE_NUM=$(echo "$BRANCH" | grep -oE '[0-9]+' | head -1 || true)
    if [ -n "$ISSUE_NUM" ]; then
        echo "Active issue (#$ISSUE_NUM):"
        $GH issue view "$ISSUE_NUM" --json title,body \
            --jq '"  Title: \(.title)\n  Body: \(.body | split("\n") | map(select(length > 0)) | join("\n  "))"' 2>/dev/null \
            | head -30 || echo "  (could not fetch issue)"
        echo ""
    fi

    # Last workflow run
    echo "Last workflow run:"
    $GH run list --limit 1 --json conclusion,displayTitle,createdAt \
        --jq '.[] | "  \(.displayTitle): \(.conclusion) (\(.createdAt))"' 2>/dev/null \
        || echo "  (no runs or gh not configured)"
    echo ""
fi

echo "=== END SESSION CONTEXT ==="
