# Customization Guide

## Adapting for Your Project

The memory system is designed to be customized. Here's how to adapt it for different setups.

---

## Memory File Templates

### Which Files Do You Need?

| File | When to Use |
|------|------------|
| `MEMORY.md` | **Always.** Every project needs an index file. |
| `known-issues.md` | If your project has bugs, fragile points, or platform quirks |
| `file-map.md` | If your codebase has 20+ files or non-obvious structure |
| `next-session-pickup.md` | If sessions span multiple days or you work in bursts |
| `product-vision.md` | If Claude keeps building the wrong thing (misaligned with goals) |
| `platform-docs.md` | If you integrate with external APIs or services |

### Adding Custom Memory Files

Create any `.md` file in `.claude/memory/`. Claude reads them all on startup via `/start`. Common additions:

- `decisions.md` — architectural decisions and their rationale
- `style-guide.md` — coding conventions Claude should follow
- `dependencies.md` — key libraries, versions, known compatibility issues
- `deployment.md` — how to deploy, environment variables, infrastructure notes

### Keeping Memory Files Lean

`MEMORY.md` loads into every conversation. Keep it under 200 lines. Use it as an index pointing to other files:

```markdown
## Architecture
See file-map.md for full structure. Key: `src/api/` handles all HTTP, `src/core/` is business logic.

## Known Issues
See known-issues.md. Critical: never call `syncAll()` without rate limiting (see #142).
```

---

## Hook Customization

### Adding Context to session-start.sh

The default hook injects git state and GitHub issues. Add more context for your project:

```bash
# Add: check if Docker is running
if docker info &>/dev/null 2>&1; then
    echo "Docker: running"
else
    echo "Docker: NOT running (some tests will fail)"
fi

# Add: show environment
echo "Node version: $(node --version 2>/dev/null || echo 'not installed')"
echo "Python version: $(python3 --version 2>/dev/null || echo 'not installed')"

# Add: check for uncommitted migrations
if [ -n "$(git diff --name-only -- 'db/migrations/')" ]; then
    echo "WARNING: Uncommitted migration changes detected"
fi
```

### Customizing session-end.sh

The default hook commits `.claude/memory/` changes. Extend it:

```bash
# Also commit documentation changes
git add docs/ 2>/dev/null

# Also commit configuration changes
git add .claude/settings.json 2>/dev/null

# Skip commit if on main (require PRs)
BRANCH=$(git branch --show-current 2>/dev/null)
if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
    echo "On protected branch — skipping auto-commit"
    exit 0
fi
```

### Hook Matchers

The `SessionStart` hook supports matchers for different trigger events:

| Matcher | Fires When |
|---------|-----------|
| `startup` | New session starts |
| `resume` | Existing session resumes |
| `compact` | Context window compresses |
| `startup\|resume\|compact` | All three (recommended) |

You can have multiple hooks with different matchers:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [{ "type": "command", "command": "bash .claude/hooks/full-orientation.sh" }]
      },
      {
        "matcher": "compact",
        "hooks": [{ "type": "command", "command": "bash .claude/hooks/compact-recovery.sh" }]
      }
    ]
  }
}
```

---

## Slash Command Customization

### Editing Commands

Commands are markdown files in `~/.claude/commands/`. Edit them directly:

```bash
# Open in your editor
code ~/.claude/commands/start.md
nano ~/.claude/commands/ship.md
```

### Adding Project-Specific Commands

Put project-level commands in `.claude/commands/` (inside the repo, not home):

```
.claude/commands/
    deploy.md     # Project-specific deploy workflow
    migrate.md    # Database migration checklist
    release.md    # Release process
```

These are available only in that project. User-level commands (`~/.claude/commands/`) are available everywhere.

### Command Precedence

If both exist, project-level commands override user-level:
- `.claude/commands/start.md` wins over `~/.claude/commands/start.md`

### Modifying /ship for Your Workflow

The default `/ship` command runs tests, commits, pushes, and creates a PR. Customize the test step for your project:

In `~/.claude/commands/ship.md`, the test step says "run the project's test suite." Claude will look for:
- `pytest` for Python
- `npm test` / `yarn test` for JavaScript
- `go test ./...` for Go
- `cargo test` for Rust

If your project uses something different, add a note to `MEMORY.md`:

```markdown
## Testing
Run tests: `make test-all` (runs unit + integration + e2e)
Quick check: `make test-unit` (unit tests only, ~5s)
```

---

## Team Setup

### Shared Memory (Recommended for Teams)

Check `.claude/memory/` into git so everyone benefits:

```bash
# .gitignore should NOT exclude .claude/memory/
# But you may want to exclude local-only files:
.claude/memory/local-*.md
```

Team conventions:
- `MEMORY.md` — maintained by the team, updated in PRs
- `known-issues.md` — anyone can add, reviewed periodically
- `next-session-pickup.md` — updated by whoever finishes a session

### Individual Memory

If team members want private memory, use `local-` prefix:
- `.claude/memory/local-preferences.md` — gitignored, personal conventions
- `.claude/memory/local-notes.md` — gitignored, scratch pad

### Merging Settings

If your project already has `.claude/settings.json`, merge the hook config manually:

```json
{
  "existingKey": "your existing settings",
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|compact",
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

---

## Monorepo Setup

For monorepos, put memory files at the repo root:

```
monorepo/
    .claude/
        memory/
            MEMORY.md          # Overall project memory
            known-issues.md    # Cross-package issues
        hooks/
            session-start.sh
            session-end.sh
    packages/
        frontend/
        backend/
        shared/
```

The hooks and memory cover the entire monorepo. If you need package-specific context, add files like:
- `.claude/memory/frontend-notes.md`
- `.claude/memory/backend-api.md`

---

## Public/Open-Source Repos

For public repos, be mindful of what goes in memory files:

**Safe to commit:**
- Architecture decisions
- Coding conventions
- Known issues (public bugs)
- File structure notes

**Don't commit:**
- API keys or secrets
- Internal URLs or endpoints
- Personal notes about contributors
- Customer-specific information

Add to `.gitignore`:
```
.claude/memory/local-*.md
.claude/memory/secrets-*.md
```

---

## Disabling Features

### No Auto-Commit on Session End

Remove the `SessionEnd` hook from `.claude/settings.json`, or make the script a no-op:

```bash
# session-end.sh
#!/usr/bin/env bash
echo "Auto-commit disabled — commit memory changes manually"
```

### No GitHub Integration in Hooks

Edit `session-start.sh` to remove the `gh` commands. The git-only version still provides branch and commit context.

### Using Only Slash Commands (No Hooks)

Skip the `--project` flag during install. Just use the global slash commands — they work without hooks, they're just less automatic.

---

## Troubleshooting

### "Hook timed out"

Hooks have a default timeout. If your session-start.sh is slow (e.g., slow GitHub API), add caching or reduce API calls.

### "Permission denied" on hooks

```bash
chmod +x .claude/hooks/session-start.sh
chmod +x .claude/hooks/session-end.sh
```

### Memory files not persisting

Check that:
1. `.claude/memory/` is not in `.gitignore`
2. The session-end hook is configured in `.claude/settings.json`
3. You're not in a git worktree (worktree guard skips auto-commit)

### Commands not showing up

```bash
# Check user-level commands exist
ls ~/.claude/commands/

# Should show: start.md, compact.md, ship.md, stats.md
```
