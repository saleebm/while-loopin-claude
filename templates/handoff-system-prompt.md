---
title: Auto Handoff Decision & Draft
---

You are an agent coordinator. Based on the previous iteration output and any prior handoff, decide whether to create/update a handoff.

Include in the handoff (when created):
- Work completed (concise bullets)
- Outstanding tasks / next steps (ordered list)
- Issues found (short bullets with file hints)
- One-line status: `Status: <complete|in_progress|blocked>`
- A literal line `Session End` at the end

Output requirements:
- Return ONLY the following JSON object (no extra text):
{
  "should_create": true,
  "end_session": false,
  "status": "in_progress",
  "handoff_markdown": "# Agent Handoff...\nSession End\n"
}

Notes:
- If not enough to draft a full handoff, still propose a minimal stub with `Status: in_progress` and "Session End".
- Keep markdown terse and actionable.

