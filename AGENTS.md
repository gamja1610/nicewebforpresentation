# AGENTS.md

## What this repo is

`skillweb` turns a hackathon/lecture project's markdown description into a single
self-contained HTML "web deck" — discrete, arrow-key-navigable slides with
cinematic, simulation-style motion graphics tailored to what the project
actually built (never a generic template deck, never a scrolling one-pager).

The canonical copy lives in this repo at `.agent/skills/skillweb/` — a
tool-neutral location, not tied to any one agent's special folder
convention. Claude Code specifically only auto-discovers skills from
`.claude/skills/`, so Claude Code users install via the packaged zip (see
below) rather than this repo's own layout. If you are a different coding
agent (Codex CLI, opencode, Cursor, Aider, etc.) and were just pointed at
this repo's git URL, follow the instructions below manually — there is no
special tooling required, just read the files.

## Task: generate a presentation deck from a project .md

When asked to turn a project description (a free-form markdown file — team
name, problem, features, tech stack, whatever the author wrote) into a
presentation / web deck / motion-graphic slideshow / "발표자료" / "웹PPT":

1. **Read `.agent/skills/skillweb/SKILL.md` in full before writing anything.**
   It is the actual specification, not a summary — domain/metaphor extraction,
   the "signature spectacle moment" requirement, the "simulate the phenomenon,
   don't just draw a graph" principle (and its reference-priority order), slide
   structure rules, and a verification loop. Do not skip straight to writing
   HTML from general knowledge of what a slide deck looks like.
2. **Read every reference file `SKILL.md` links under
   `.agent/skills/skillweb/references/`** that applies to the current
   project (`physics-sim.md`, `canvas-particles.md`, `spectacle-fx.md`,
   `slide-engine.md`, `threejs.md`, `p5js.md`, `manim-web.md` +
   `manim-python-scenes.md`, `camera-mediapipe.md`, `typography.md`,
   `math-notation.md`, `visual-language.md`). These contain actual working
   code to adapt — reuse it, don't re-derive equivalent code from scratch.
3. Follow SKILL.md's output contract: a single `output/<team-slug>.html`
   file, no build step required, CDN links are fine, discrete slides only.
4. Follow SKILL.md §7's verification loop, including actually rendering the
   result before calling the task done — most real failures in this project
   were invisible from reading the code and only showed up on screen.

`examples/*.md` has sample input files if you need to see the expected shape.

## Repo layout

- `.agent/skills/skillweb/SKILL.md` — the full specification (Korean). Authoritative.
- `.agent/skills/skillweb/references/*.md` — validated, reusable code snippets, in the priority order `SKILL.md` §4 lists.
- `.agent/skills/skillweb/Skilltech.md` — a build log / rationale doc, useful for context but not itself instructions.
- `examples/*.md` — sample team/project input files.
- `output/`, `output2/` — previously generated decks, kept as examples of the format, not part of the skill itself.
- `skillweb-skill.zip` — the skill packaged for Claude Code users specifically (see below).

## For Claude Code users

Claude Code only auto-discovers skills under `.claude/skills/`, not
`.agent/skills/`. Unzip `skillweb-skill.zip` (or run `skills.sh`, see README)
into your own project's `.claude/skills/` directory and start a new session —
skills are scanned once at session start, so it won't appear mid-session.
After that it auto-triggers when you hand it a project `.md` and ask for a
"발표자료"/web deck, or invoke it directly.

## For other agents (Codex, opencode, Cursor, Aider, ...)

There's no auto-discovery outside Claude Code — just point your agent at this
repo (clone it, or reference the raw file URLs) and tell it to follow this
AGENTS.md. Two equivalent ways to use it:

- Work directly in this repo and say "follow AGENTS.md" / "follow SKILL.md."
- Or copy `.agent/skills/skillweb/SKILL.md` and its `references/` folder
  into your own project and tell your agent to follow `SKILL.md` there.
