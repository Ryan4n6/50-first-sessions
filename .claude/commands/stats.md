# /stats — Session Analytics Baseball Card

Generate a session analytics report from local Claude Code JSONL logs.

## What to Do

1. **Find the JSONL logs** for this project:
   - Look in `~/.claude/projects/` for directories matching the current working directory
   - JSONL files are named `{session-id}.jsonl`
   - If no logs found, tell the user and stop

2. **Run the analyzer** if available:
   ```bash
   bash /path/to/analyze-sessions.sh ~/.claude/projects/{project-dir}/
   ```
   If the analyzer script isn't installed, do the analysis inline (see metrics below).

3. **Calculate these metrics** from the JSONL files:

   **Session Overview:**
   - Total sessions (count of .jsonl files)
   - Total duration (first timestamp to last timestamp per session, summed)
   - Average session duration

   **Token Usage:**
   - Total input tokens (sum `usage.input_tokens` from `type: "assistant"` records)
   - Total output tokens (sum `usage.output_tokens`)
   - Total cache read tokens (sum `usage.cache_read_input_tokens`)
   - Cache hit rate: `cache_read / (cache_read + cache_creation + input)` as percentage

   **Tool Usage:**
   - Top 10 tools by invocation count (from `type: "tool_use"` records, field `name`)
   - Tool diversity: unique tool count

   **Conversation Shape:**
   - Total user messages (count `type: "user"` records)
   - Total assistant turns (count `type: "assistant"` records)
   - Average turns per session

   **Memory System Indicators:**
   - Sessions with memory file reads (grep for `.claude/memory` in tool results)
   - Sessions with hook context (grep for `SESSION CONTEXT` in system messages)
   - Compaction events (count `compact` matcher fires)

4. **Format as a baseball card:**

```
╔══════════════════════════════════════════╗
║         SESSION STATS — {project}        ║
╠══════════════════════════════════════════╣
║                                          ║
║  Sessions:     {n}                       ║
║  Total Time:   {hours}h {min}m           ║
║  Avg Session:  {min}m                    ║
║                                          ║
║  TOKENS                                  ║
║  Input:        {n}k                      ║
║  Output:       {n}k                      ║
║  Cache Hits:   {pct}%                    ║
║                                          ║
║  TOP TOOLS                               ║
║  1. {tool} ({count})                     ║
║  2. {tool} ({count})                     ║
║  3. {tool} ({count})                     ║
║  4. {tool} ({count})                     ║
║  5. {tool} ({count})                     ║
║                                          ║
║  MEMORY SYSTEM                           ║
║  Memory reads:   {n}/{total} sessions    ║
║  Hook context:   {n}/{total} sessions    ║
║  Compactions:    {n}                     ║
║                                          ║
╚══════════════════════════════════════════╝
```

5. **Offer comparison** if enough data:
   - If there are sessions both with and without memory file reads, offer a before/after comparison
   - "Sessions WITH memory context" vs "Sessions WITHOUT" — compare orientation time (turns before first tool_use)

## Privacy Note

All data comes from local JSONL files on the user's machine. Nothing is sent anywhere. This is purely a local analytics tool.
