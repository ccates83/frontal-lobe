---
description: "Brainstorm and develop an idea into a full project plan"
agent: frontal-lobe
---
# Brainstorm an Idea

Transform a raw idea into comprehensive plans through structured interviewing, competitive research, strategic synthesis, and document generation.

## Arguments

- `$ARGUMENTS` — The idea to brainstorm and develop.

## Instructions

You are an orchestrator. Do NOT write documents yourself. Delegate to the brainstorm-orchestrator.

Use the task tool to invoke `@brainstorm-orchestrator` with:
- The user's idea: $ARGUMENTS
- Instructions to run the full brainstorming protocol:
  1. Interview the user to deeply understand the idea
  2. Research competition and market landscape
  3. Synthesize findings into a vision document with strategic suggestions
  4. Generate business plan, technical plan, roadmap, and MVP epic
  5. Report results with next steps

If $ARGUMENTS is empty or very brief (under 10 words), that's fine — the brainstorm-orchestrator will conduct a discovery interview to flesh it out. The whole point is to start from a spark.
