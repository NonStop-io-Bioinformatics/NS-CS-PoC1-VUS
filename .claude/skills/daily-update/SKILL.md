---
name: daily-update
description: Draft the daily standup/status update for THIS project (NS_CS_PoC1) in the "Yesterday / Today" format. Use whenever the user asks to write, draft, or generate their daily update, standup, status update, EOD/BOD report, or "what I did / what I'm doing today".
---

# Daily update — NS_CS_PoC1

Project-scoped skill: it encodes this project's update conventions. (Other projects
have their own `.claude/skills/daily-update`.)

Produce a daily standup update in this **exact format** (plain header lines, not markdown headings):

```
Yesterday:
- <what was accomplished>
Today:
- <what is planned>
Blockers:
- <if any blockers -> mention blockers in bullet points. Or else just mention "None">
```

## Project conventions (NS_CS_PoC1)
- Audience: the NonStop team working the Claude Science genomic-diagnostics PoC.
- Bullets are outcome-focused and refer to project pieces by name where useful
  (the 4 MCP connectors, Report Service, Report DB, the Mr. Dibbs Happy Path, etc.).
- Keep credentials/PHI out of updates (the data is synthetic, but keep the habit).

## Steps

1. **Establish the window.** Today = current date; "Yesterday" = the previous working day. Do not print dates unless asked.

2. **Gather "Yesterday" (what was done)** — in priority order:
   - Anything the user pasted or described in the request → primary source, use their facts.
   - Accomplishments from the current conversation/session (things built, shipped, verified).
   - Git activity in this repo:
     `git log --author="$(git config user.name)" --since=yesterday --pretty=format:'%s'`
     Summarize commits into **outcomes**, don't paste raw commit messages.
   - If the signal is thin, ask the user for 2-3 highlights instead of guessing or padding.

3. **Gather "Today" (the plan):**
   - Use the tasks the user names (they usually list them).
   - Otherwise infer from yesterday's open threads, next steps, or leftover TODOs.
   - If still unclear, ask for today's top priorities.

4. **Write the bullets:**
   - Concise and outcome-focused; past tense for Yesterday, action verbs for Today.
   - Lead with impact ("Got X working end-to-end"), not a blow-by-blow of steps.
   - Group related items; aim for **3-6 bullets per section**.
   - Bold key terms sparingly. No hedging, no filler.

5. **Output** the update in the exact format above, then offer two quick variants:
   - **Management-facing** — outcomes/impact, minimal tooling detail.
   - **Technical** — for the team, includes the how.

## Rules
- Keep it standup-length — skimmable in ~15 seconds.
- Never invent work that didn't happen. If unsure whether something actually shipped, leave it out or flag it.
- Expect follow-ups (tone tweaks, "do today as well", trimming) — the user iterates on these.

## Optional
- If the user wants a running log, append the dated update to `daily-updates.md` in the repo root (create if missing) under a `## <YYYY-MM-DD>` heading.
