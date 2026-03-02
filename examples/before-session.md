# Before: Cold Start (No Memory System)

> What a typical session looks like WITHOUT persistent memory.

---

**User:** Fix the API rate limiting bug

**Claude:** I'd be happy to help fix the API rate limiting bug. Let me start by exploring the codebase to understand the project structure.

*[reads 15 files over 3 minutes]*

**Claude:** I can see this is a data pipeline project. Let me understand the architecture...

*[reads 8 more files]*

**Claude:** I see there's an API module. Can you tell me which API is having the rate limiting issue?

**User:** The one we've been working on for the last 3 sessions. The external data API.

**Claude:** I don't have context from previous sessions. Let me look for API-related code...

*[reads 6 more files, finds 3 API integrations]*

**Claude:** I see three API integrations. Which one has the rate limiting bug?

**User:** *[sighs]* The reporting API. The one that broke last Tuesday.

**Claude:** Let me look at the reporting API module...

*[reads the file]*

**Claude:** I see the issue — there's no rate limiting at all. Should I add one?

**User:** No, we ADDED rate limiting last session but it's too aggressive. It's throttling at 10 requests/minute but the API allows 100.

**Claude:** Ah, I see. Let me look for rate limiting code...

*[finally finds the rate limiter, 8 minutes into the session]*

---

**Total orientation time: ~8 minutes**
**User frustration: High** (had to re-explain context 3 times)
**Repeated work: Yes** (re-discovered architecture, re-found the relevant files)
**Risk of mistakes: High** (no memory of why rate limiting was set to 10 — maybe there was a reason)

---

## Why This Happens

Every Claude Code session starts with a blank slate. Claude doesn't know:
- What the project does
- What you worked on last session
- What decisions were made and why
- Which files are relevant to your current work
- What broke before and how it was fixed

The human becomes the memory system — manually re-briefing Claude every single session.
