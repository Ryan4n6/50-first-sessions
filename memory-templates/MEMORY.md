# Memory Index

<!-- This is the main memory file. Claude reads it first on every session start. -->
<!-- Keep it under 200 lines. Link to other memory files for details. -->

## Quick Links
- [known-issues.md](known-issues.md) — Open issues, recently shipped, what's next
- [file-map.md](file-map.md) — What every significant file does
- [next-session-pickup.md](next-session-pickup.md) — Session handover notes

## Core Architecture
<!-- Describe your project's architecture in 5-10 bullet points. -->
<!-- This is what Claude needs to "just know" without reading any files. -->

- **What this project does**: <!-- one sentence -->
- **Tech stack**: <!-- languages, frameworks, key dependencies -->
- **Entry points**: <!-- main scripts, CLI commands, API endpoints -->
- **Data flow**: <!-- how data moves through the system -->

## Key Patterns
<!-- Conventions that aren't obvious from the code itself. -->
<!-- Example: "All API routes use snake_case", "Tests mock at the _fetch() boundary" -->

## Session Ramp-Up Checklist
1. Read this file + linked files above
2. `git log --oneline -10` to see recent changes
3. Check known-issues.md for current priorities
4. You're ready to work in 2-3 turns
