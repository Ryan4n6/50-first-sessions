# 50 First Sessions

**Because Claude keeps forgetting who you are.**

<p align="center">
  <img src="assets/hero.png" alt="50 First Sessions — She forgets everything. Every. Single. Session." width="700">
</p>

A session memory system for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Three hooks, four slash commands, and a set of memory file templates that cure Claude's amnesia problem.

---

## The Problem

Every Claude Code session starts from scratch. Your AI pair programmer wakes up each morning with no idea who you are, what your project does, what you shipped yesterday, or what's on fire today. It re-reads your codebase, re-discovers your conventions, and asks the same orientation questions — burning 15-20% of your context window before doing anything useful.

You are Adam Sandler. Claude is Drew Barrymore. Every single morning, you re-introduce yourself from scratch. Unlike the movie, there is no romantic payoff. Just wasted tokens and repeated explanations.

## The Fix

A three-layer system that gives Claude persistent memory:

```
 Layer 3: Slash Commands (/start, /compact, /ship, /stats)
 ══════════════════════════════════════════════════════════
 Human-triggered checkpoints. /start orients Claude.
 /compact saves state before memory wipe. /ship closes
 out branches with full documentation. /stats proves it works.

 Layer 2: Session Hooks (fire automatically)
 ══════════════════════════════════════════════════════════
 SessionStart: injects git state, open issues, recent
 commits, and memory file contents into context.
 SessionEnd: auto-commits memory file changes to git.
 Compact: re-injects full context after compaction.

 Layer 1: Memory Files (.claude/memory/)
 ══════════════════════════════════════════════════════════
 Git-tracked knowledge base. Architecture, open issues,
 file map, session handover notes. Survives everything.
 Updated by commands, read by hooks, persisted by git.
```

## Quick Start

### Option A: Install Script

```bash
curl -sSL https://raw.githubusercontent.com/Ryan4n6/50-first-sessions/main/install.sh | bash
```

This installs the four slash commands globally (`~/.claude/commands/`). Then, in any project:

```bash
cd your-project
curl -sSL https://raw.githubusercontent.com/Ryan4n6/50-first-sessions/main/install.sh | bash -s -- --project
```

This sets up hooks and memory templates for that specific project.

### Option B: Manual Install

```bash
# Global (once — works across all projects)
cp commands/*.md ~/.claude/commands/

# Per project (from inside your project directory)
mkdir -p .claude/hooks .claude/memory
cp hooks/* .claude/hooks/
cp config/settings.json .claude/settings.json
cp memory-templates/* .claude/memory/
chmod +x .claude/hooks/*.sh
```

## What's in the Box

| File | What It Does |
|------|-------------|
| `commands/start.md` | `/start` — Session kickoff. Reads memory, checks git/GitHub, orients you in 3-4 sentences. |
| `commands/compact.md` | `/compact` — Saves working state to memory files + GitHub before context compaction. |
| `commands/ship.md` | `/ship` — Full branch close-out: tests, acceptance criteria, closing comments, labels, lessons learned. |
| `commands/stats.md` | `/stats` — Baseball card of session metrics from your Claude Code logs. |
| `hooks/session-start.sh` | Auto-fires on session start/resume/compact. Injects branch, commits, issues, memory into context. |
| `hooks/session-end.sh` | Auto-fires on session end. Commits memory file changes to git. Worktree-safe. |
| `config/settings.json` | Template for `.claude/settings.json` — wires up the hooks. |
| `memory-templates/` | 6 starter memory files: architecture, issues, file map, handover, vision, platform docs. |
| `playbook.md` | Plain-English guide for non-technical users. "No git knowledge needed." |

## Before & After

**Without 50 First Sessions** (cold start):
```
You: Fix the auth bug
Claude: I'd be happy to help! Can you tell me about your project?
You: It's a data pipeline that...
Claude: What language/framework?
You: Python, and the auth module is at...
Claude: Let me read the codebase... *reads 40 files*
Claude: I see. What testing framework do you use?
You: pytest, and...
[15 turns later, Claude finally starts working]
```

**With 50 First Sessions** (warm start):
```
You: /start
Claude: On branch `main`. Top priority: #89 (auth bug). Last shipped:
        PR #42 (rate limiting). What do you want to work on?
You: Fix the auth bug
Claude: Reading issue #89... I see the problem is in core/auth.py:142.
        Let me write a fix and a regression test.
[2 turns to productive work]
```

## Clear Without Fear

One underrated benefit: **you can aggressively clear context without losing anything.**

Claude Code's context window fills up. When it does, you have three options — all of which used to mean losing your working state:

| Action | What It Does | Without Memory | With Memory |
|--------|-------------|---------------|-------------|
| `/compact` | Compresses context | Lossy — nuance disappears | `/compact` command saves state first |
| `/clear` | Wipes conversation | Everything gone | Memory files persist in git |
| Help → Clear Cache & Restart | Nuclear option | Total amnesia | Hooks re-inject context on restart |

With 50 First Sessions installed, even the most aggressive reset — clearing cache and restarting the entire application — just means Claude wakes up, hooks fire, memory loads, and you're back in 5 seconds.

**Stop hoarding context.** Clear early, clear often. Your memory files survive everything.

## Memory Files

The memory system uses 6 files in `.claude/memory/`. Not all are required — start with the first three:

| File | Purpose | Required? |
|------|---------|-----------|
| `MEMORY.md` | Architecture index, key patterns, session ramp-up checklist | Yes |
| `known-issues.md` | P0/P1/P2 issues, recently shipped, what's next, lessons learned | Yes |
| `next-session-pickup.md` | Session handover: where you are, next steps, expensive-to-rediscover context | Yes |
| `file-map.md` | What every file does, one-line descriptions | Recommended |
| `product-vision.md` | The "why" — core insight, design principles, stakeholders | Optional |
| `platform-docs.md` | External API intel, auth flows, fragile points | Optional |

The `memory-templates/` directory has starter versions of all 6. Copy them, fill them in, and Claude gets smarter with every session.

## The Origin Story

We learned this the hard way. [Read the full case study](docs/case-study.md).

**TL;DR:** During a marathon coding session on a complex data pipeline, auto-compaction fired mid-session and wiped Claude's working memory. The result:

- 3 issues closed with all acceptance criteria unchecked
- A code review that was conducted but never posted to GitHub
- One-sentence closing comments on critical issues
- Then Claude deleted its own git worktree and killed the session

That disaster led to this system. Every feature in 50 First Sessions exists because we watched it fail without one.

## How It Works Under the Hood

See [docs/architecture.md](docs/architecture.md) for the full technical design.

The key insight: **hooks handle the automatic parts, commands handle the human checkpoints, and memory files are the persistent state that ties them together.**

- Hooks fire without human intervention (session start/end)
- Commands fire when humans make decisions (`/compact` before context fills, `/ship` when branch is done)
- Memory files are the shared state both systems read and write

## Customization

See [docs/customization.md](docs/customization.md) for:
- Public repos (add `.claude/memory/` to `.gitignore`)
- Monorepos (per-package vs shared memory)
- Custom hooks (adding project-specific context injection)
- Teams (shared memory conventions)

## Known Limitations

- **Memory can go stale.** If you refactor code but don't update memory files, Claude will operate on outdated context. The session-start hook warns when `file-map.md` looks stale, but ultimately you need to keep memory files current.

- **Team merge conflicts.** Memory files are git-tracked. If two people edit the same branch's memory files simultaneously, you'll get merge conflicts. Mitigate by using per-branch memory updates and squash merges.

- **Windows not supported.** Hooks are bash scripts. Windows users need WSL or Git Bash.

- **Auto-commits use `--no-verify`.** To prevent hook failures from blocking memory persistence, auto-commits bypass pre-commit hooks. The session-end script includes its own secret scanning, but project-specific pre-commit checks are skipped.

- **No tests for the system itself.** The hooks and installer don't have automated tests. They're small scripts (~70 lines each) but bugs are caught by users, not CI.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (the CLI)
- `git` (for memory file persistence)
- `gh` CLI (optional, for GitHub integration — `brew install gh`)
- `jq` (optional, for `/stats` command — `brew install jq`)
- bash (hooks are shell scripts)

## Contributing

Found a bug? Have an idea? Open an issue or PR. This system was born from real failures and gets better with every one.

## License

MIT. Use it, fork it, improve it. If Claude forgets less because of this, we all win.

---

*Named after the 2004 film where Adam Sandler falls in love with Drew Barrymore, who has no long-term memory. Every morning he has to re-introduce himself. Sound familiar?*
