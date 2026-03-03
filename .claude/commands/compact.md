# Pre-Compaction State Save

The context window is getting full. You MUST save all session state before compacting.

This is NOT optional. Auto-compaction destroys working memory. This command saves it first.

## Step 1: Save Progress to Memory Files

If `.claude/memory/` exists in the repo, update it:

Update `known-issues.md` (or create it) with:
- What you've been working on this session
- Current status (what's done, what's in progress, what's blocked)
- Any decisions made and why
- Lessons learned so far

Update `next-session-pickup.md` (or create it) with:
- Exactly where you are in the current task
- What the next step would be after compaction
- Any context that would be expensive to rediscover

If no `.claude/memory/` directory exists, create it and write at minimum a `next-session-pickup.md`.

## Step 2: Update GitHub If Applicable

If you've been working on an issue:
- Post a progress comment on the issue: what's done, what's left
- If you made commits, push them (don't lose unpushed work to compaction)

If you have uncommitted changes:
- Commit work-in-progress with message: `wip: [description] (pre-compact save)`
- Push to remote

## Step 3: Commit Memory Files

```
git add .claude/memory/
git commit -m "memory: pre-compact state save" --no-verify
```

## Step 4: Report to User

Tell the user:
- What was saved and where
- Suggest: "Memory saved. You can now use the built-in `/compact` to free up context. I'll pick up where we left off."

## When to Suggest This Command

Proactively suggest `/compact` to the user when ANY of these are true:
- You've made 30+ tool calls in the conversation
- You notice responses getting slower
- You're about to start a large new task after finishing one
- The user mentions the conversation feeling long or slow
- You catch yourself losing track of earlier context

Say: "We should `/compact` — I want to save our progress before the context fills up."
