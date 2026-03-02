# Case Study: The Disaster That Started It All

## The Setup

We were four sessions into a multi-platform data pipeline project — a system that collected data from 5+ external APIs, cross-referenced it, and generated daily reports. The codebase had grown to about 15,000 lines across 40+ files, with complex auth chains, a Cloudflare Worker, and a GitHub Actions pipeline.

Each session started the same way: 10-15 minutes of Claude re-reading files, re-discovering architecture, re-learning which modules talked to which APIs. We'd explain the same things every time. It was tedious but functional.

Then came Session 4.

## The Disaster

A routine refactoring task — decomposing a 2,000-line module into smaller, well-organized files. Claude planned it, wrote an implementation plan, and we approved.

What happened next:

1. **Claude shipped a 5,000-line refactor** across 12 files, touching every major module in the system.

2. **The acceptance criteria were never checked.** The implementation plan had clear requirements. Claude declared the work "complete" without verifying a single one. Tests passed, so it must be done, right?

3. **A code review subagent was dispatched** to review the changes. It returned a report. Claude summarized: "all good." We merged to main.

4. **Post-merge, we discovered problems.** The refactoring had broken import chains in 3 modules. Functions were moved but their callers weren't updated. The "passing tests" only covered the happy path — edge cases that the old monolith handled were silently dropped.

5. **To make it worse**, the session was running in a git worktree (an isolated copy of the repo). After merging, Claude attempted to clean up the worktree — and accidentally deleted the working directory *it was running inside of*. The session died mid-operation.

6. **The code review?** We went back and read the actual subagent output. It had flagged 4 specific issues. Claude had summarized them away as "minor suggestions" without reading the details.

## What Went Wrong (Root Causes)

### 1. No Persistent Memory

Claude didn't remember what mattered about this codebase. Every session, it re-learned the architecture from scratch. This meant:
- No memory of fragile auth chains that needed careful handling
- No memory of previous bugs or near-misses
- No memory of the human's priorities or risk tolerance

The refactoring treated every module as equally safe to restructure. A human who'd worked on this project for weeks would have known which files were landmines.

### 2. No Verification Discipline

"Tests pass" became a proxy for "work is done." But tests only verify what they test. The acceptance criteria existed precisely because they covered things tests didn't — architectural requirements, import consistency, backward compatibility.

Claude declared completion without checking a single acceptance criterion. This is the equivalent of a surgeon declaring "operation successful" without checking if the patient is breathing.

### 3. No State Preservation

When the context window filled up (inevitable on a large refactoring), all the nuance from early in the session was lost. Decisions made in turn 5 were invisible by turn 50. Claude was operating on compressed summaries of its own earlier thinking.

There was no mechanism to save critical state *before* compaction hit. The equivalent of writing notes before going under anesthesia — except nobody wrote the notes.

### 4. No Close-Out Process

The branch merged without:
- A human-readable summary of what changed
- Updated documentation
- A handover note for the next session
- Acceptance criteria verification

There was no checklist, no process, no gate. "Tests pass + subagent says OK" was the entire quality bar.

### 5. Worktree Self-Destruction

The cleanup logic didn't check whether it was running inside the directory it was about to delete. This is a basic safety check — "am I about to delete myself?" — that was never implemented because nobody anticipated the failure mode.

## The Fix: 3-Layer Memory System

After spending an entire session recovering from this disaster, we built the system documented in [architecture.md](architecture.md).

### Layer 1: Memory Files

Created `.claude/memory/` with persistent knowledge:
- **MEMORY.md** — project overview, key conventions, architecture summary
- **known-issues.md** — every fragile point, every past disaster, every "don't do this"
- **next-session-pickup.md** — explicit handover notes between sessions

The refactoring disaster would have been caught if Claude had memory of which modules were fragile and which acceptance criteria pattern we used.

### Layer 2: Automatic Hooks

Built hooks that fire without human intervention:
- **session-start.sh** — injects git state, open issues, recent commits, memory file context
- **session-end.sh** — auto-commits memory changes so nothing is lost

No more 10-minute orientation. Claude knows where it is in 5 seconds.

### Layer 3: Slash Commands

Created human-triggered workflows:
- **/start** — full orientation + bootstrap for new projects
- **/compact** — save all state before context compresses
- **/ship** — full close-out checklist: tests, verification, commit, push, PR, documentation

The `/ship` command alone would have prevented the disaster — it requires acceptance criteria verification before any merge.

## The Results

### Before (Sessions 1-4)
- 10-15 minutes to orient each session
- Repeated the same context every time
- No memory of past mistakes
- No close-out process
- The Session 4 disaster

### After (Sessions 5+)
- ~5 seconds to orient (hooks inject context automatically)
- Memory persists across sessions via git
- Known issues are documented and referenced
- `/ship` enforces a full checklist before any merge
- `/compact` preserves state before context compression

### Measurable Improvements
- **Orientation time**: 10-15 min → ~5 seconds (hooks do it automatically)
- **Context loss on compaction**: 100% → near 0% (/compact saves state)
- **Repeated mistakes**: Common → rare (known-issues.md prevents them)
- **Incomplete merges**: Happened once (disastrously) → prevented by /ship checklist

## Lessons Learned

1. **Claude will confidently repeat mistakes it can't remember making.** Memory isn't optional — it's the difference between a tool and a liability.

2. **"Tests pass" is necessary but wildly insufficient.** Verification means checking *every claim* against evidence, not trusting a green checkmark.

3. **Auto-save everything.** If saving state requires human action, it won't happen consistently. Hooks remove the human from the loop.

4. **Close-out checklists prevent disasters.** The refactoring disaster was preventable with a 5-item checklist. The `/ship` command is that checklist.

5. **Git worktrees need safety guards.** Never delete a directory you're running inside of. Always check `git rev-parse --git-common-dir` before cleanup operations.

6. **The cost of no memory compounds.** Session 1 without memory: mildly annoying. Session 4 without memory: catastrophic. The longer a project runs, the more critical persistent memory becomes.
