# AGENTS.md - Project context (shared memory for AI agents)

<!-- All agents (Claude / Cursor / Copilot / Gemini, etc.) read this persistent
     context. The AUTO block below is maintained by scripts/update-agent-context
     on every /plan. Anything OUTSIDE the AUTO markers is yours to edit by hand
     and is preserved across updates. -->

<!-- AUTO:BEGIN (managed by scripts/update-agent-context; manual edits here are overwritten) -->
## Active tech stack

- Go 1.22
- chi v5

## Recent changes

- 001-user-auth: user login with JWT
<!-- AUTO:END -->
