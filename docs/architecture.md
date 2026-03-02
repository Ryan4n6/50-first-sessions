# Architecture: The 3-Layer Memory System

## The Problem

Claude Code has no persistent memory between sessions. Every conversation starts from zero — no knowledge of what you built yesterday, what broke, what decisions were made, or what's next.

This means every session begins with the same expensive ritual: re-reading files, re-discovering architecture, re-learning conventions. Worse, without memory of past mistakes, Claude will confidently repeat them.

## The Solution: 3 Layers

```
Layer 1: Memory Files (.claude/memory/)
    Persistent knowledge base — what Claude needs to know
    Checked into git, versioned, shared across machines

Layer 2: Hooks (.claude/hooks/)
    Automatic context injection — no human action needed
    Session-start: injects git state + GitHub issues + recent work + memory
    Session-end: auto-commits memory file changes

Layer 3: Slash Commands (~/.claude/commands/)
    Human-triggered workflows — /start, /compact, /ship, /stats
    Installed globally, work on any project
```

### How They Work Together

```
Session starts
    → Hook fires automatically
    → Injects branch, recent commits, open issues, pipeline status
    → Claude reads memory files (architecture, known issues, next steps)
    → Claude is oriented in ~5 seconds, not ~5 minutes

During work
    → Claude updates memory files as it learns
    → /compact saves state before context compresses

Session ends
    → Hook fires automatically
    → Memory file changes committed to git
    → Next session picks up exactly where this one left off
```

## Layer 1: Memory Files

Memory files live in `.claude/memory/` and are checked into git. This is the knowledge base that persists across sessions.

| File | Purpose |
|------|---------|
| `MEMORY.md` | Index file — project overview, conventions, architecture summary |
| `known-issues.md` | Bugs, fragile points, things that break — so Claude doesn't re-discover them |
| `file-map.md` | Key files and what they do — faster than re-reading the whole codebase |
| `next-session-pickup.md` | Handover notes — what shipped, what's next, what to watch out for |
| `product-vision.md` | (Optional) Why the product exists, who it's for, design principles |
| `platform-docs.md` | (Optional) API details, auth flows, undocumented behaviors |

### Why Git, Not Local Files?

Memory files could live anywhere. We chose git-tracked files because:

1. **Versioned** — you can see how understanding evolved over time
2. **Shared** — works across machines, CI, team members
3. **Auditable** — `git log .claude/memory/` shows what Claude learned and when
4. **Backed up** — no single point of failure
5. **Diffable** — PR reviews can catch incorrect memory

### Memory File Principles

- **Append, don't rewrite** — add new knowledge, don't delete old context
- **Date your entries** — timestamps help distinguish current from stale info
- **Keep MEMORY.md under 200 lines** — it loads into every conversation, keep it lean
- **Use other files for detail** — MEMORY.md is the index, not the encyclopedia

## Layer 2: Hooks

Hooks are shell scripts that fire automatically on Claude Code lifecycle events. No human action required.

### session-start.sh

Fires on: new session, resume, compaction recovery

Injects:
- Current git branch
- Last 5 commits (what shipped recently)
- Top 5 open issues by priority (what needs attention)
- Last CI/CD pipeline run status (is anything broken?)
- Memory file headers (quick orientation)

This gives Claude immediate situational awareness without the human having to explain anything.

### session-end.sh

Fires on: session exit

Does:
- `git add .claude/memory/` — stages any memory file changes
- Commits with auto-generated message
- Only runs if there are actual changes
- Worktree safety guard: skips if running inside a git worktree (prevents committing to temp branches)

This ensures memory changes are never lost, even if the human forgets to commit.

### Hook Configuration

Hooks are configured in `.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume|compact",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/session-start.sh"
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "bash .claude/hooks/session-end.sh"
          }
        ]
      }
    ]
  }
}
```

## Layer 3: Slash Commands

Slash commands are human-triggered workflows. They live at `~/.claude/commands/` (user-level, work on every project).

| Command | When | What It Does |
|---------|------|-------------|
| `/start` | Beginning of session | Full orientation: reads memory, checks git/GitHub, offers to bootstrap new projects |
| `/compact` | Session getting long | Saves all state to memory files before context compresses |
| `/ship` | Done with a branch | Full close-out: tests, commit, push, PR, issue updates, memory handover |
| `/stats` | Want metrics | Session analytics from local JSONL logs — your "baseball card" |

### Why Global, Not Per-Project?

Commands are the same workflow regardless of project. The hooks and memory files are project-specific (they reference local paths and project context), but the commands are generic workflows that adapt to whatever project they find themselves in.

## Design Decisions

### Why Shell Scripts for Hooks?

- Zero dependencies — bash is everywhere
- Fast — hooks should add milliseconds, not seconds
- Debuggable — `bash -x .claude/hooks/session-start.sh` shows exactly what runs
- Composable — pipe, grep, sed, awk all available

### Why Markdown for Memory?

- Claude reads markdown natively
- Humans can read/edit it too
- Git diffs are clean and meaningful
- No parsing needed — it's just text

### Why Not a Database?

Databases add complexity (schemas, migrations, queries) for a problem that's fundamentally about text. Memory files are simple, portable, versionable, and human-readable. The tradeoff is no structured queries, but Claude can grep and parse markdown just fine.

### Why Three Layers?

Each layer solves a different failure mode:

| Failure | Without Layer | With Layer |
|---------|--------------|-----------|
| Claude doesn't know the project | Memory files missing | **Layer 1** — persistent knowledge |
| Human forgets to brief Claude | No automation | **Layer 2** — hooks inject context automatically |
| Human forgets to save state | Knowledge lost | **Layer 2** — auto-commit on session end |
| Context window fills up | State lost on compaction | **Layer 3** — /compact saves before compression |
| Branch ships without docs | No close-out process | **Layer 3** — /ship enforces checklist |

No single layer is sufficient. Together, they cover every transition point where knowledge would otherwise be lost.
