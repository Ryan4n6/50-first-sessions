# Parallel Session Supervision with tmux

## The Problem

Claude Code's context window is finite. Large implementation plans (10+ tasks) will either:
1. Run out of context mid-way and lose state
2. Require manual re-orientation after each compaction
3. Burn tokens on re-reading files instead of writing code

## The Solution: Supervisor + Executor

Run two Claude Code sessions simultaneously:
- **Executor**: Fresh context per task, `--dangerously-skip-permissions` for autonomous execution
- **Supervisor**: Watches the executor in real-time via tmux, intervenes if needed

```
┌─────────────────────────────────────────────────┐
│  tmux session: "impl"                           │
│                                                 │
│  ┌─────────────────┐  ┌──────────────────────┐  │
│  │   Supervisor     │  │     Executor         │  │
│  │   (your session) │  │  (autonomous)        │  │
│  │                  │  │                      │  │
│  │  watches output  │  │  claude --danger...  │  │
│  │  checks git log  │  │  executing-plans     │  │
│  │  reviews commits │  │  task by task        │  │
│  │  can intervene   │  │  commits as it goes  │  │
│  │                  │  │                      │  │
│  └─────────────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────────┘
```

## Quick Start

```bash
# One command to launch the full monitoring dashboard
bash docs/scripts/watch-session.sh /path/to/project
```

This creates a tmux session with 3 panes:

```
┌──────────────────────────────────┐
│                                  │
│     Claude Code (executor)       │
│     You see every tool call,     │
│     every file read, every test  │
│                                  │
├─────────────────┬────────────────┤
│  Git Monitor    │  File Watcher  │
│  live commits   │  modified .py  │
│  working tree   │  new tests     │
└─────────────────┴────────────────┘
```

**tmux cheat sheet:**
| Key | What It Does |
|-----|-------------|
| `Ctrl+B`, arrow keys | Switch between panes |
| `Ctrl+B`, `Z` | Zoom/unzoom a pane (fullscreen toggle) |
| `Ctrl+B`, `D` | Detach (session keeps running in background) |
| `tmux attach -t claude-watch` | Re-attach from any terminal |

## Manual Setup

### 1. Create an Implementation Plan

Use the brainstorming and writing-plans skills to create a plan document at `docs/plans/YYYY-MM-DD-feature-name.md`. The plan should have bite-sized TDD tasks with exact file paths and complete code.

### 2. Launch the Executor in tmux

```bash
# Create a named tmux session with the executor
tmux new-session -d -s impl \
  "cd /path/to/worktree && claude --dangerously-skip-permissions"

# Attach to watch it live (detach with Ctrl+B, D)
tmux attach -t impl
```

Once attached, give it the plan:

```
Use superpowers:executing-plans to implement docs/plans/YYYY-MM-DD-feature-name.md
```

Then detach (`Ctrl+B, D`) and return to your supervisor session.

### 3. Monitor from the Supervisor

```bash
# Snapshot what the executor is currently showing
tmux capture-pane -t impl -p

# Last 100 lines of output
tmux capture-pane -t impl -p -S -100

# Watch git commits appear in real-time
watch -n 5 'git log --oneline -10'

# Check what files are being modified
git status --short

# Read uncommitted work in progress
git diff --stat
```

### 4. Intervene if Needed

```bash
# Send keystrokes to the executor (e.g., interrupt it)
tmux send-keys -t impl C-c

# Send a message
tmux send-keys -t impl "stop — you're modifying the wrong file" Enter

# Kill it if it's going off the rails
tmux send-keys -t impl C-c C-c
```

## Why This Works

| Problem | How This Solves It |
|---------|-------------------|
| Context window exhaustion | Executor gets fresh context per task via executing-plans skill |
| Blind autonomous execution | Supervisor watches in real-time, can intervene |
| Lost state between tasks | Git commits after each task preserve progress |
| No quality control | Supervisor reviews each commit before moving on |
| Token waste on re-orientation | SessionStart hook re-injects context automatically |

## When to Use This

- Implementation plans with 5+ tasks
- Migrations touching many files
- Any autonomous session where you want visibility without burning your own context
- When you want to do other work while Claude implements a plan

## When NOT to Use This

- Simple 1-3 task changes (just do them in your session)
- Exploratory work where direction isn't clear yet (use brainstorming skill instead)
- Tasks requiring frequent human decisions (just work interactively)

## Tips

- **Use git worktrees** for isolation — the executor works in its own copy of the repo, can't break your working tree
- **Bake in pause points** at critical tasks (e.g., before infrastructure changes that need manual UI work)
- **Check commits, not screen output** — git log is the ground truth of what actually shipped
- **Don't duplicate work** — if the executor is researching something, don't also search for it in your session
- **Pre-configure secrets** before launching — the executor can't ask you for passwords or API keys in `--dangerously-skip-permissions` mode

## Forensic Auditing

The strongest reason to watch: **Claude's summaries are lossy.**

When Claude reports "I updated the auth module and fixed the tests," you're trusting its judgment about what happened. The tmux pane shows the raw feed — every `Read`, every `Grep`, every `Edit` with actual file paths and content. You see what *actually* happened, not the summary.

**What the raw feed catches that summaries don't:**

- **Wrong file reads** — Claude opens `auth.py` when it should have opened `auth/clever_sso.py`
- **Phantom searches** — grepping for a function name that doesn't exist, then silently moving on
- **Edit drift** — modifying line 145 when the bug is on line 245
- **TDD violations** — writing implementation before tests (the summary will still say "TDD")
- **Context waste** — re-reading the same file 5 times because it forgot the contents
- **Silent failures** — a test command returns non-zero but Claude keeps going

The git monitor pane catches **drift at the commit level**. If commits start appearing that don't match the plan, you see it in real-time instead of discovering 15 bad commits later.

It's the difference between reading the incident report and watching the body camera footage.

## Learning by Watching

The second benefit: **watching Claude work teaches you how Claude works.**

When you delegate a task and come back to a finished PR, you learn nothing. When you watch the tmux pane in real-time, you see:

- Which files Claude reads before making changes (and which it skips)
- How it structures tests before writing implementation (TDD in action)
- What search patterns it uses to find code (`Grep` vs `Glob` vs `Read`)
- When it makes mistakes and how it recovers
- The exact sequence of tool calls for common operations

This turns delegation into apprenticeship. You're not just getting work done — you're learning the patterns that make AI-assisted development effective. Next time, you can guide Claude better because you've seen how it thinks.

**Pro tip:** Zoom into the executor pane (`Ctrl+B, Z`) during interesting moments — like when it's debugging a failing test or refactoring a complex function. That's where the real learning happens.
