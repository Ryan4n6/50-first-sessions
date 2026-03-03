# Design: Address Gemini Code Review Findings

**Date:** 2026-03-02
**Trigger:** External code review from Gemini identified bugs, design concerns, and documentation gaps.

---

## Scope

Three categories of work:
1. **Bug fixes** (3 concrete bugs in scripts)
2. **Design improvements** (memory staleness, commit noise, secret scanning)
3. **Documentation updates** (architecture doc discrepancy, known limitations section)

---

## Bug Fixes

### Bug 1: `install.sh` echo bug (line 30)

**Problem:** `echo "  Installed /\$cmd"` prints literal `$cmd` instead of the interpolated command name.

**Fix:** Remove the backslash escape. Change to `echo "  Installed /$cmd"`.

**Files:** `install.sh`

---

### Bug 2: Branch number extraction false positives (session-start.sh line 53)

**Problem:** `grep -oE '[0-9]+' | head -1` matches any digit sequence in a branch name. Branch `feature/v2-redesign` would try to look up issue #2.

**Fix:** Use a more targeted regex that looks for issue-number conventions. Match numbers that appear after common prefixes (`#`, `-`, `/`) or at the end of the branch name, preferring the last numeric segment (which is more likely the issue number in patterns like `feat/123-description`).

Replace:
```bash
ISSUE_NUM=$(echo "$BRANCH" | grep -oE '[0-9]+' | head -1 || true)
```

With:
```bash
# Match issue numbers: branch patterns like issue-42, feat/42-desc, fix/#42, or trailing numbers
# Skip version-like patterns (v2, v10) by requiring a prefix of #, -, or /
ISSUE_NUM=$(echo "$BRANCH" | grep -oE '(#|[-/])([0-9]+)' | grep -oE '[0-9]+' | tail -1 || true)
```

The `tail -1` prefers the last match, which in `fix/v2-issue-42-auth` correctly yields `42` instead of `2`.

**Files:** `hooks/session-start.sh`

---

### Bug 3: Fragile worktree detection (session-end.sh line 21)

**Problem:** `echo "$GIT_COMMON" | grep -q '/worktrees/'` matches the string `/worktrees/` anywhere in the path. A project directory named `worktrees` would false-positive.

**Fix:** Use git's own mechanism: compare `--git-dir` and `--git-common-dir`. In a worktree, these differ. In a normal repo, they're the same.

Replace:
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

**Files:** `hooks/session-end.sh`

---

## Design Improvements

### Design 1: Memory staleness detection

**Problem:** If source code changes but memory files don't get updated, Claude operates on stale context — which is worse than no context. Nothing warns the user.

**Approach:** Add a lightweight staleness check to `session-start.sh`. Compare the last-modified timestamp of key memory files against recent source file changes. Print a warning if memory files look stale.

**Implementation:**
```bash
# Memory staleness check
if [ -f "$REPO_ROOT/.claude/memory/file-map.md" ]; then
    MEMORY_AGE=$(stat -f %m "$REPO_ROOT/.claude/memory/file-map.md" 2>/dev/null || \
                 stat -c %Y "$REPO_ROOT/.claude/memory/file-map.md" 2>/dev/null || echo 0)
    # Count source files modified after file-map.md was last updated
    STALE_COUNT=$(find "$REPO_ROOT" -name '*.py' -o -name '*.js' -o -name '*.ts' -o -name '*.go' -o -name '*.rs' \
        | head -200 \
        | while read f; do
            FILE_MOD=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null || echo 0)
            [ "$FILE_MOD" -gt "$MEMORY_AGE" ] && echo stale
          done | wc -l | tr -d ' ')
    if [ "$STALE_COUNT" -gt 5 ]; then
        echo "WARNING: file-map.md may be stale ($STALE_COUNT source files changed since last update)"
    fi
fi
```

**Portability note:** `stat -f %m` is macOS, `stat -c %Y` is Linux. The script tries both.

**Design constraints:**
- Advisory only (warning, not blocking)
- Threshold of 5 files to avoid noise from minor edits
- Caps `find` at 200 files to keep it fast
- Only checks `file-map.md` (the most staleness-prone file)

**Files:** `hooks/session-start.sh`

---

### Design 2: Better auto-commit messages

**Problem:** Generic commit messages (`memory: auto-persist session learnings`) create noisy git history.

**Approach:** Include the branch name and changed file names in the commit message. Also add documentation recommending squash merges for feature branches.

**Implementation in session-end.sh:**
```bash
BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
CHANGED_FILES=$(git diff --cached --name-only | sed 's|.claude/memory/||' | tr '\n' ', ' | sed 's/,$//')
git commit -m "memory($BRANCH): update $CHANGED_FILES" --no-verify 2>/dev/null || true
```

Example output: `memory(feat/42-auth): update known-issues.md, MEMORY.md`

**Documentation addition:** Add a note in `docs/customization.md` under a "Git History" section recommending squash merges to collapse memory commits when merging feature branches.

**Files:** `hooks/session-end.sh`, `docs/customization.md`

---

### Design 3: Pre-commit secret scanning

**Problem:** `--no-verify` bypasses all pre-commit hooks, including any secret scanning the user has configured. Memory files could accidentally contain API keys or tokens.

**Approach:** Add a minimal inline secret scan in `session-end.sh` before the commit. This runs regardless of `--no-verify` since it's built into the script itself.

**Implementation:**
```bash
# Quick secret scan before committing
SECRETS_FOUND=$(git diff --cached --diff-filter=AM -- .claude/memory/ | \
    grep -iE '(api[_-]?key|secret|token|password|credential|private[_-]?key)\s*[:=]' | \
    grep -vE '(example|placeholder|your-|TODO|CHANGEME|xxx)' || true)
if [ -n "$SECRETS_FOUND" ]; then
    echo "WARNING: Possible secrets detected in memory files. Skipping auto-commit."
    echo "Review staged changes with: git diff --cached .claude/memory/"
    git reset HEAD .claude/memory/ 2>/dev/null || true
else
    git commit -m "memory($BRANCH): update $CHANGED_FILES" --no-verify 2>/dev/null || true
    echo "Auto-committed $CHANGED memory file(s)."
fi
```

**Design constraints:**
- Scans only the diff (not full file contents) — fast
- Common false positive exclusions (example, placeholder, TODO)
- On detection: unstages files and warns instead of committing
- User can review and commit manually

**Files:** `hooks/session-end.sh`

---

## Documentation Updates

### Doc 1: Fix architecture.md / settings.json discrepancy

**Problem:** `docs/architecture.md` line 111 shows a combined matcher `"startup|resume|compact"` but `config/settings.json` uses three separate entries.

**Fix:** Update the architecture doc example to match the shipped config (three separate entries), and add a note explaining why.

**Files:** `docs/architecture.md`

---

### Doc 2: Add "Known Limitations" section to README

**Problem:** Several valid concerns from the Gemini review aren't documented anywhere users would see them.

**Content for new section:**

```markdown
## Known Limitations

- **Memory can go stale.** If you refactor code but don't update memory files,
  Claude will operate on outdated context. The session-start hook warns when
  `file-map.md` looks stale, but ultimately you need to keep memory files current.

- **Team merge conflicts.** Memory files are git-tracked. If two people edit the
  same branch's memory files simultaneously, you'll get merge conflicts. Mitigate
  by using per-branch memory updates and squash merges.

- **Windows not supported.** Hooks are bash scripts. Windows users need WSL or
  Git Bash.

- **Auto-commits use `--no-verify`.** To prevent hook failures from blocking
  memory persistence, auto-commits bypass pre-commit hooks. The session-end script
  includes its own secret scanning, but project-specific pre-commit checks are skipped.

- **No tests for the system itself.** The hooks and installer don't have automated
  tests. They're small scripts (~70 lines each) but bugs are caught by users, not CI.
```

**Files:** `README.md`

---

### Doc 3: Add "Git History" section to customization.md

**Problem:** Auto-commit noise in git history is a valid concern with no documented mitigation.

**Content:**

```markdown
## Managing Git History

### Auto-Commit Messages

The session-end hook creates commits like `memory(feat/42-auth): update known-issues.md`.
On long-lived branches, these can accumulate.

**Recommended mitigations:**

- **Squash merge feature branches** — `gh pr merge --squash` collapses all commits
  (including memory commits) into one clean commit on main.
- **Interactive rebase before PR** — `git rebase -i main` lets you squash memory
  commits into related work commits.
- **Disable auto-commit** — Remove the `SessionEnd` hook from `.claude/settings.json`
  and commit memory files manually with `/compact` or `/ship`.
```

**Files:** `docs/customization.md`

---

## Files Changed (Summary)

| File | Changes |
|------|---------|
| `install.sh` | Fix echo bug (line 30) |
| `hooks/session-start.sh` | Fix branch number regex, add staleness detection |
| `hooks/session-end.sh` | Fix worktree detection, improve commit messages, add secret scanning |
| `docs/architecture.md` | Fix settings.json example to match shipped config |
| `docs/customization.md` | Add "Managing Git History" section |
| `README.md` | Add "Known Limitations" section |
