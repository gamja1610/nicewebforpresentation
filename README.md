# nicewebforpresentation

Turns a hackathon/lecture project's markdown description into a single
self-contained HTML "web deck" — discrete, arrow-key-navigable slides with
motion graphics tailored to what the project actually built.

- **Using this with an AI coding agent (Claude Code, Codex CLI, opencode, Cursor, Aider, ...)?**
  See [AGENTS.md](AGENTS.md) — point your agent at this repo's URL and it has
  everything it needs.
- **One-liner install (any agent)**:
  `curl -fsSL https://raw.githubusercontent.com/gamja1610/nicewebforpresentation/main/skills.sh | bash`
- **Claude Code specifically**: unzip `skillweb-skill.zip` into your project's
  `.claude/skills/` (Claude Code only auto-discovers skills there, not
  `.agent/skills/`) and start a new session.
- The actual specification lives in this repo at
  [`.agent/skills/skillweb/SKILL.md`](.agent/skills/skillweb/SKILL.md), with
  reusable implementation snippets under
  [`.agent/skills/skillweb/references/`](.agent/skills/skillweb/references/).
