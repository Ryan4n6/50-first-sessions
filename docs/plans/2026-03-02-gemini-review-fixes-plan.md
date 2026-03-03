# Gemini Review Fixes — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix 3 bugs, add 3 design improvements, and update 3 docs — all identified from an external Gemini code review.

**Architecture:** Shell script edits + markdown documentation updates. No new files, no new dependencies. All changes are to existing files in a ~150-line bash codebase.

**Tech Stack:** Bash, Git, Markdown

---

### Task 1: Fix install.sh echo bug

**Files:**
- Modify: `install.sh:30`

**Step 1: Verify the bug**

Run: `bash -c 'for cmd in start compact; do echo "  Installed /\$cmd → dir/$cmd.md"; done'`
Expected: Prints literal `$cmd` instead of `start` / `compact`

**Step 2: Fix the echo line**

In `install.sh` line 30, change:
```bash
    echo "  Installed /\$cmd → $COMMANDS_DIR/$cmd.md"
```
to:
```bash
    echo "  Installed /$cmd → $COMMANDS_DIR/$cmd.md"
```

Remove the backslash before `$cmd`. The `$COMMANDS_DIR/$cmd.md` part on the right side already interpolates correctly — only the left side `\$cmd` is broken.

**Step 3: Verify the fix**

Run: `bash -c 'for cmd in start compact; do echo "  Installed /$cmd → dir/$cmd.md"; done'`
Expected: `Installed /start → dir/start.md` and `Installed /compact → dir/compact.md`

**Step 4: Commit**

```bash
git add install.sh
git commit -m "fix: install.sh echo prints literal \$cmd instead of command name"
```

---

### Task 2: Fix branch number extraction false positives

**Files:**
- Modify: `hooks/session-start.sh:53`

**Step 1: Verify the bug**

Run: `echo "feature/v2-redesign" | grep -oE '[0-9]+' | head -1`
Expected: `2` (wrong — should not match version numbers)

**Step 2: Apply the fix**

In `hooks/session-start.sh` line 53, change:
```bash
    ISSUE_NUM=$(echo "$BRANCH" | grep -oE '[0-9]+' | head -1 || true)
```
to:
```bash
    # Match issue numbers after common prefixes (#, -, /). Prefer last match
    # to skip version prefixes like v2 in "fix/v2-issue-42-auth"
    ISSUE_NUM=$(echo "$BRANCH" | grep -oE '(#|[-/])([0-9]+)' | grep -oE '[0-9]+' | tail -1 || true)
```

**Step 3: Verify the fix with test cases**

Run each of these and confirm the output:

```bash
# Should extract 42 (issue number after /)
echo "feat/42-auth-bug" | grep -oE '(#|[-/])([0-9]+)' | grep -oE '[0-9]+' | tail -1

# Should extract 42 (skips v2)
echo "fix/v2-issue-42-auth" | grep -oE '(#|[-/])([0-9]+)' | grep -oE '[0-9]+' | tail -1

# Should extract nothing (no issue-like number)
echo "feature/v2-redesign" | grep -oE '(#|[-/])([0-9]+)' | grep -oE '[0-9]+' | tail -1

# Should extract 123
echo "issue-123" | grep -oE '(#|[-/])([0-9]+)' | grep -oE '[0-9]+' | tail -1

# Should extract 89
echo "fix/#89" | grep -oE '(#|[-/])([0-9]+)' | grep -oE '[0-9]+' | tail -1

# Should extract nothing (main has no issue)
echo "main" | grep -oE '(#|[-/])([0-9]+)' | grep -oE '[0-9]+' | tail -1
```

Expected results: `42`, `42`, (empty), `123`, `89`, (empty)

**Step 4: Commit**

```bash
git add hooks/session-start.sh
git commit -m "fix: branch number extraction skips version prefixes like v2"
```

---

### Task 3: Fix fragile worktree detection

**Files:**
- Modify: `hooks/session-end.sh:19-23`

**Step 1: Verify current behavior in this worktree**

We are running inside a worktree right now. Confirm:

```bash
git rev-parse --git-dir
git rev-parse --git-common-dir
```

Expected: These two paths should be different (proving we're in a worktree).

**Step 2: Apply the fix**

In `hooks/session-end.sh`, replace lines 19-23:
```bash
IN_WORKTREE=false
GIT_COMMON="$(git rev-parse --git-common-dir 2>/dev/null || echo "")"
if echo "$GIT_COMMON" | grep -q '/worktrees/'; then
    IN_WORKTREE=true
fi
```

With:
```bash
IN_WORKTREE=false
GIT_DIR="$(git rev-parse --git-dir 2>/dev/null || echo "")"
GIT_COMMON="$(git rev-parse --git-common-dir 2>/dev/null || echo "")"
if [ -n "$GIT_DIR" ] && [ -n "$GIT_COMMON" ] && [ "$GIT_DIR" != "$GIT_COMMON" ]; then
    IN_WORKTREE=true
fi
```

**Step 3: Verify the fix**

```bash
# Should detect worktree (we're in one right now)
GIT_DIR="$(git rev-parse --git-dir)" && GIT_COMMON="$(git rev-parse --git-common-dir)" && [ "$GIT_DIR" != "$GIT_COMMON" ] && echo "WORKTREE" || echo "NORMAL"
```

Expected: `WORKTREE`

**Step 4: Commit**

```bash
git add hooks/session-end.sh
git commit -m "fix: worktree detection uses git-dir comparison instead of path string match"
```

---

### Task 4: Add memory staleness detection to session-start.sh

**Files:**
- Modify: `hooks/session-start.sh` (add before `echo "=== END SESSION CONTEXT ==="`)

**Step 1: Add the staleness check**

Insert the following block before the final `echo "=== END SESSION CONTEXT ==="` line in `hooks/session-start.sh`:

```bash
# Memory staleness check
if [ -f "$REPO_ROOT/.claude/memory/file-map.md" ]; then
    MEMORY_AGE=$(stat -f %m "$REPO_ROOT/.claude/memory/file-map.md" 2>/dev/null || \
                 stat -c %Y "$REPO_ROOT/.claude/memory/file-map.md" 2>/dev/null || echo 0)
    # Count source files modified after file-map.md was last updated
    STALE_COUNT=$(find "$REPO_ROOT" -name '*.py' -o -name '*.js' -o -name '*.ts' -o -name '*.go' -o -name '*.rs' \
        2>/dev/null | head -200 \
        | while read f; do
            FILE_MOD=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0)
            [ "$FILE_MOD" -gt "$MEMORY_AGE" ] && echo stale
          done | wc -l | tr -d ' ')
    if [ "$STALE_COUNT" -gt 5 ]; then
        echo "WARNING: file-map.md may be stale ($STALE_COUNT source files changed since last update)"
        echo ""
    fi
fi
```

**Step 2: Verify it runs without errors**

Run: `bash hooks/session-start.sh 2>&1 | tail -5`
Expected: Should complete without errors (no file-map.md exists in this repo, so the check is skipped silently).

**Step 3: Commit**

```bash
git add hooks/session-start.sh
git commit -m "feat: warn when file-map.md looks stale relative to source files"
```

---

### Task 5: Improve session-end.sh — better commit messages + secret scanning

**Files:**
- Modify: `hooks/session-end.sh`

**Step 1: Rewrite the commit section**

Replace the existing commit block in `hooks/session-end.sh` (the section from `# Check if there's anything to commit` through the commit) with:

```bash
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
```

**Step 2: Verify the script is syntactically valid**

Run: `bash -n hooks/session-end.sh`
Expected: No output (no syntax errors)

**Step 3: Commit**

```bash
git add hooks/session-end.sh
git commit -m "feat: improve auto-commit messages and add inline secret scanning"
```

---

### Task 6: Fix architecture.md settings.json discrepancy

**Files:**
- Modify: `docs/architecture.md:108-135`

**Step 1: Update the hook config example**

Replace the JSON example in `docs/architecture.md` (lines 108-135, the code block inside "Hook Configuration") with:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          { "type": "command", "command": "bash .claude/hooks/session-start.sh" }
        ]
      },
      {
        "matcher": "resume",
        "hooks": [
          { "type": "command", "command": "bash .claude/hooks/session-start.sh" }
        ]
      },
      {
        "matcher": "compact",
        "hooks": [
          { "type": "command", "command": "bash .claude/hooks/session-start.sh" }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [
          { "type": "command", "command": "bash .claude/hooks/session-end.sh" }
        ]
      }
    ]
  }
}
```

This matches what `config/settings.json` actually ships.

**Step 2: Update the worktree safety description**

Line 100 says "Worktree safety guard: skips if running inside a git worktree". Update to reflect the new behavior — it no longer skips, it commits to the worktree branch and leaves cleanup to the user. Change to:
"Worktree safety guard: commits to worktree branch but never deletes the worktree or branch"

**Step 3: Commit**

```bash
git add docs/architecture.md
git commit -m "docs: fix architecture.md to match shipped settings.json config"
```

---

### Task 7: Add "Known Limitations" to README

**Files:**
- Modify: `README.md`

**Step 1: Add the section**

Insert a `## Known Limitations` section in `README.md` after the "Customization" section and before "Requirements". Content:

```markdown
## Known Limitations

- **Memory can go stale.** If you refactor code but don't update memory files, Claude will operate on outdated context. The session-start hook warns when `file-map.md` looks stale, but ultimately you need to keep memory files current.

- **Team merge conflicts.** Memory files are git-tracked. If two people edit the same branch's memory files simultaneously, you'll get merge conflicts. Mitigate by using per-branch memory updates and squash merges.

- **Windows not supported.** Hooks are bash scripts. Windows users need WSL or Git Bash.

- **Auto-commits use `--no-verify`.** To prevent hook failures from blocking memory persistence, auto-commits bypass pre-commit hooks. The session-end script includes its own secret scanning, but project-specific pre-commit checks are skipped.

- **No tests for the system itself.** The hooks and installer don't have automated tests. They're small scripts (~70 lines each) but bugs are caught by users, not CI.
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add Known Limitations section to README"
```

---

### Task 8: Add "Managing Git History" to customization.md

**Files:**
- Modify: `docs/customization.md`

**Step 1: Add the section**

Insert a `## Managing Git History` section in `docs/customization.md` after the "Public/Open-Source Repos" section and before "Disabling Features". Content:

```markdown
## Managing Git History

### Auto-Commit Messages

The session-end hook creates commits like `memory(feat/42-auth): update known-issues.md`.
On long-lived branches, these can accumulate.

**Recommended mitigations:**

- **Squash merge feature branches** — `gh pr merge --squash` collapses all commits (including memory commits) into one clean commit on main.
- **Interactive rebase before PR** — `git rebase -i main` lets you squash memory commits into related work commits.
- **Disable auto-commit** — Remove the `SessionEnd` hook from `.claude/settings.json` and commit memory files manually with `/compact` or `/ship`.
```

**Step 2: Commit**

```bash
git add docs/customization.md
git commit -m "docs: add Managing Git History section to customization guide"
```

---

### Task 9: Final verification

**Step 1: Run both hooks and confirm no errors**

```bash
bash hooks/session-start.sh 2>&1 | head -30
bash -n hooks/session-end.sh
bash -n install.sh
```

Expected: session-start.sh produces context output, both syntax checks pass with no output.

**Step 2: Review all changes since starting**

```bash
git log --oneline HEAD~8..HEAD
```

Expected: 8 commits, one per task.
