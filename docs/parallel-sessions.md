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

## Setup

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
