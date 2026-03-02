#!/usr/bin/env bash
# analyze-sessions.sh — Parse Claude Code JSONL logs into a baseball card
#
# Usage:
#   bash analyze-sessions.sh [project-dir]
#
# Arguments:
#   project-dir   Path to JSONL directory (default: auto-detect from cwd)
#                 Usually: ~/.claude/projects/-Users-you-your-project/
#
# Dependencies: bash, python3 (jq used if available, python3 fallback)
# Output: Formatted session stats to stdout

set -euo pipefail

# ─── Find Project Directory ────────────────────────────────────
if [ -n "${1:-}" ]; then
    PROJECT_DIR="$1"
else
    # Auto-detect from cwd
    CWD_ESCAPED=$(pwd | sed 's|/|-|g')
    PROJECT_DIR="$HOME/.claude/projects/$CWD_ESCAPED"
fi

if [ ! -d "$PROJECT_DIR" ]; then
    echo "No JSONL logs found at: $PROJECT_DIR"
    echo "Usage: bash analyze-sessions.sh ~/.claude/projects/{project-dir}/"
    exit 1
fi

JSONL_FILES=("$PROJECT_DIR"/*.jsonl)
if [ ${#JSONL_FILES[@]} -eq 0 ] || [ ! -f "${JSONL_FILES[0]}" ]; then
    echo "No .jsonl files found in: $PROJECT_DIR"
    exit 1
fi

NUM_SESSIONS=${#JSONL_FILES[@]}

# ─── Use Python for parsing (reliable, no jq dependency) ──────
python3 << 'PYTHON_SCRIPT' - "$PROJECT_DIR" "$NUM_SESSIONS"
import json
import sys
import os
import glob
from datetime import datetime, timedelta
from collections import Counter

project_dir = sys.argv[1]
num_sessions = int(sys.argv[2])

jsonl_files = sorted(glob.glob(os.path.join(project_dir, "*.jsonl")))

total_input = 0
total_output = 0
total_cache_read = 0
total_cache_create = 0
tool_counts = Counter()
total_user_msgs = 0
total_assistant_turns = 0
session_durations = []
memory_read_sessions = 0
hook_context_sessions = 0
compaction_events = 0

for fpath in jsonl_files:
    first_ts = None
    last_ts = None
    has_memory_read = False
    has_hook_context = False

    try:
        with open(fpath, 'r') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    rec = json.loads(line)
                except json.JSONDecodeError:
                    continue

                # Timestamps for duration
                ts_str = rec.get("timestamp")
                if ts_str:
                    try:
                        ts = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
                        if first_ts is None or ts < first_ts:
                            first_ts = ts
                        if last_ts is None or ts > last_ts:
                            last_ts = ts
                    except (ValueError, TypeError):
                        pass

                rec_type = rec.get("type", "")

                # Token usage from assistant messages
                if rec_type == "assistant":
                    total_assistant_turns += 1
                    msg = rec.get("message", {})
                    usage = msg.get("usage", {})
                    total_input += usage.get("input_tokens", 0)
                    total_output += usage.get("output_tokens", 0)
                    total_cache_read += usage.get("cache_read_input_tokens", 0)
                    total_cache_create += usage.get("cache_creation_input_tokens", 0)

                    # Check for tool_use in content
                    content = msg.get("content", [])
                    if isinstance(content, list):
                        for block in content:
                            if isinstance(block, dict) and block.get("type") == "tool_use":
                                tool_name = block.get("name", "unknown")
                                tool_counts[tool_name] += 1

                # User messages
                elif rec_type == "user":
                    total_user_msgs += 1
                    msg = rec.get("message", {})
                    content = msg.get("content", "")
                    content_str = json.dumps(content) if isinstance(content, (list, dict)) else str(content)

                    if ".claude/memory" in content_str:
                        has_memory_read = True
                    if "SESSION CONTEXT" in content_str:
                        has_hook_context = True
                    if "compact" in content_str.lower():
                        compaction_events += 1

                # System messages (hook output)
                elif rec_type == "system":
                    msg = rec.get("message", {})
                    content = msg.get("content", "")
                    content_str = json.dumps(content) if isinstance(content, (list, dict)) else str(content)
                    if "SESSION CONTEXT" in content_str:
                        has_hook_context = True

    except (IOError, OSError):
        continue

    if has_memory_read:
        memory_read_sessions += 1
    if has_hook_context:
        hook_context_sessions += 1

    if first_ts and last_ts:
        duration = (last_ts - first_ts).total_seconds()
        if duration > 0:
            session_durations.append(duration)

# ─── Calculate stats ──────────────────────────────────────────
total_time_s = sum(session_durations)
total_hours = int(total_time_s // 3600)
total_mins = int((total_time_s % 3600) // 60)

avg_duration_s = total_time_s / len(session_durations) if session_durations else 0
avg_mins = int(avg_duration_s // 60)

total_all_input = total_input + total_cache_read + total_cache_create
cache_hit_pct = (total_cache_read / total_all_input * 100) if total_all_input > 0 else 0

input_k = total_input / 1000
output_k = total_output / 1000
cache_read_k = total_cache_read / 1000

avg_turns = total_assistant_turns / num_sessions if num_sessions > 0 else 0

top_tools = tool_counts.most_common(10)

# ─── Derive project name from directory ───────────────────────
project_name = os.path.basename(project_dir).replace("-Users-", "").split("-")
project_name = project_name[-1] if project_name else "unknown"

# ─── Format Output ────────────────────────────────────────────
W = 48  # inner width

def row(text=""):
    """Pad text to fixed width inside box borders."""
    return f"|{text:<{W}}|"

def sep():
    return f"+{'=' * W}+"

print()
print(sep())
print(f"|{'SESSION STATS':^{W}}|")
print(sep())
print(row())
print(row(f"  Sessions:            {num_sessions}"))
print(row(f"  Total Time:          {total_hours}h {total_mins}m"))
print(row(f"  Avg Session:         {avg_mins}m"))
print(row())
print(row("  TOKENS"))
print(row(f"  Input:           {input_k:>10.1f}k"))
print(row(f"  Output:          {output_k:>10.1f}k"))
print(row(f"  Cache Reads:     {cache_read_k:>10.1f}k"))
print(row(f"  Cache Hit Rate:  {cache_hit_pct:>9.1f}%"))
print(row())
print(row("  TOP TOOLS"))

for i, (tool, count) in enumerate(top_tools[:10], 1):
    display = tool
    if display.startswith("mcp__"):
        parts = display.split("__")
        display = parts[-1] if len(parts) >= 3 else display
    if len(display) > 22:
        display = display[:19] + "..."
    print(row(f"  {i:>2}. {display:<22} ({count})"))

print(row())
print(row("  CONVERSATION"))
print(row(f"  User Messages:       {total_user_msgs}"))
print(row(f"  Assistant Turns:     {total_assistant_turns}"))
print(row(f"  Avg Turns/Session:   {avg_turns:.0f}"))
print(row())
print(row("  MEMORY SYSTEM"))
print(row(f"  Memory Reads:        {memory_read_sessions}/{num_sessions} sessions"))
print(row(f"  Hook Context:        {hook_context_sessions}/{num_sessions} sessions"))
print(row(f"  Compactions:         {compaction_events}"))
print(row())
print(sep())
print()
print("  Data: local JSONL logs (nothing sent externally)")
print(f"  Path: {project_dir}")
print()

PYTHON_SCRIPT
