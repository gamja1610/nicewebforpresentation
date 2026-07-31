# nicewebforpresentation

Turns a hackathon/lecture project's markdown description into a single
self-contained HTML "web deck" — discrete, arrow-key-navigable slides with
motion graphics tailored to what the project actually built.

- **Using this with an AI coding agent (Claude Code, Codex CLI, opencode, Cursor, Aider, ...)?**
  See [AGENTS.md](AGENTS.md) — point your agent at this repo's URL and it has
  everything it needs.
- **Claude Code specifically**: unzip `skillweb-skill.zip` into your project's
  `.claude/skills/` and start a new session.
- The actual specification lives at
  [`.claude/skills/skillweb/SKILL.md`](.claude/skills/skillweb/SKILL.md), with
  reusable implementation snippets under
  [`.claude/skills/skillweb/references/`](.claude/skills/skillweb/references/).
