# How To Use Claude Code With 50 First Sessions

No git knowledge needed. Just follow these steps.

---

## Starting a Session

Open your terminal and type:

```
claude
```

That's it. The session hook fires automatically, and Claude already knows:
- What branch you're on
- What issues are open
- What shipped recently
- What the last workflow run looked like

**You don't need to explain what the project is.** Claude reads its memory files on startup.

Just tell it what you want:
- "Fix the login bug"
- "Add rate limiting to the API"
- "Refactor the database module"

---

## While You're Working

You don't need to do anything special. Claude will:
- Create a branch if it needs one
- Write and run tests
- Track progress with a todo list you can see

**If Claude asks a technical question you don't understand**, just say "I don't know, use your best judgment" -- that's fine.

**If you want Claude to explain what it's doing**, say "explain in plain English."

**If the session gets long** and Claude mentions "compaction" or things feel slow, run `/compact` to save your progress before the context fills up.

---

## Finishing a Task

When Claude says it's done, say one of these:

**"Commit and push"** -- saves the work to GitHub on the current branch.

**"Create a PR"** -- pushes to GitHub and opens a pull request.

**"Merge to main"** -- merges into the main branch if tests pass.

**"Commit, push, and make a PR"** -- does all three. Usually what you want.

---

## The Four Commands

| Command | When to Use It |
|---------|---------------|
| `/start` | Beginning of every session. Claude orients itself automatically. |
| `/compact` | When the session gets long. Saves state before context compresses. |
| `/ship` | When you're done with a branch. Full close-out with documentation. |
| `/stats` | When you want to see session metrics. Your "baseball card." |

---

## After You're Done

Just close the terminal or type `exit`. The session-end hook automatically:
1. Saves any memory file changes
2. Commits them to git so the next session has them

**You don't need to remember anything.** The system remembers for you.

---

## If Something Goes Wrong

### "Claude doesn't know what the project is"
The session-start hook might have failed. Run: `bash .claude/hooks/session-start.sh` and paste the output to Claude.

### "Claude is confused about what branch it's on"
Say: "Run git status and tell me where we are."

### "Claude deleted something it shouldn't have"
Say: "Undo the last commit" or "Reset to where we were before." Git keeps history -- nothing is truly lost.

### "The commands aren't working"
Check that the files exist: `ls ~/.claude/commands/` should show `start.md`, `compact.md`, `ship.md`, `stats.md`.

---

## Quick Reference

| You Say | What Happens |
|---------|-------------|
| `claude` | Start a session. Context loaded automatically. |
| `/start` | Claude orients itself (branch, issues, recent work). |
| "Fix [thing]" | Claude investigates, plans, implements, tests. |
| `/compact` | Saves progress before context fills up. |
| "Commit and push" | Saves work to GitHub. |
| "Create a PR" | Opens a pull request on GitHub. |
| `/ship` | Full branch close-out with documentation. |
| `/stats` | Session metrics baseball card. |
| `exit` | Session ends. Memory auto-saved. |
