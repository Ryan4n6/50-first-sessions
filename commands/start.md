# Session Kickoff

You are starting a work session. Follow these steps IN ORDER before doing anything else.

## Step 1: Read Memory Files

Check if `.claude/memory/` exists in the repo root. If it does, read:
1. `MEMORY.md` — architecture, key patterns
2. `known-issues.md` — open issues, lessons learned, session handover
3. Any other files that look relevant to the current task

If no memory directory exists, note this for Step 4 — you'll offer to bootstrap it.

## Step 2: Check Git State

Run:
- `git log --oneline -5` — what shipped recently
- `git status --short` — any uncommitted work
- `git branch --show-current` — where you are

If on a feature branch, identify the linked issue number from the branch name.

## Step 3: Check GitHub State

Run:
- `gh issue list --state open --limit 5` — what's on the backlog
- If on a feature branch with an issue number: `gh issue view {number}` — read the full spec

If `gh` is not on PATH, try `export PATH="/usr/local/bin:$PATH"` first.

## Step 4: Orient the Human

Tell the user in 3-4 sentences:
- What branch you're on and what it's for
- What the top priority issue is
- What shipped most recently
- Ask: "What do you want to work on?"

If no `.claude/memory/` directory was found in Step 1, tell the user:
> "This project doesn't have memory files yet. Want me to create `.claude/memory/` with a starter MEMORY.md? It helps me remember context across sessions."

If they say yes, create `.claude/memory/MEMORY.md` with a brief architecture summary based on what you learned from git log, README, and CLAUDE.md. Add it to `.gitignore` only if the user says the repo is public.

## Context Budget Warning

You MUST monitor conversation length. If you've had more than ~30 tool calls or the conversation feels long, proactively warn:

> "Heads up — we've been going a while. Want to `/compact` to save our progress before the context fills up?"

Do NOT wait for auto-compaction. Warn early. The user would rather save state than lose it.

## What NOT To Do
- Don't read files you don't need yet (lazy-load)
- Don't start working before orienting
- Don't skip the GitHub check — issues may have been updated by other sessions
- Don't forget to monitor context length throughout the session
