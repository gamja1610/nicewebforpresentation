#!/usr/bin/env bash
# skillweb installer — spoon-feeds the skillweb Claude Code skill into a project.
#
# Usage (from the project you want the skill installed into):
#   curl -fsSL https://raw.githubusercontent.com/gamja1610/nicewebforpresentation/main/skills.sh | bash
# or:
#   ./skills.sh [target-dir]     # target-dir defaults to the current directory
set -euo pipefail

REPO="gamja1610/nicewebforpresentation"
BRANCH="main"
ZIP_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/skillweb-skill.zip"
AGENTS_URL="https://raw.githubusercontent.com/${REPO}/${BRANCH}/AGENTS.md"

DEST_ROOT="${1:-.}"
CLAUDE_SKILLS_DIR="${DEST_ROOT}/.claude/skills"
AGENT_SKILLS_DIR="${DEST_ROOT}/.agent/skills"

need() { command -v "$1" >/dev/null 2>&1; }

if ! need curl; then
  echo "error: curl is required but not found." >&2
  exit 1
fi

echo "→ Downloading skillweb-skill.zip from ${REPO}@${BRANCH} ..."
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
curl -fsSL "$ZIP_URL" -o "$TMP_DIR/skillweb-skill.zip"

mkdir -p "$CLAUDE_SKILLS_DIR"

echo "→ Extracting into ${CLAUDE_SKILLS_DIR}/skillweb ..."
# Note: the archive is built on Windows (PowerShell Compress-Archive), whose
# zip metadata makes Info-ZIP's unzip print a harmless "backslashes as path
# separators" warning and exit 1 even though extraction succeeds (entry names
# are plain forward-slash paths). So don't trust the extractor's exit code —
# turn off -e around it and verify the real result (SKILL.md landed) instead.
set +e
if need unzip; then
  unzip -oq "$TMP_DIR/skillweb-skill.zip" -d "$CLAUDE_SKILLS_DIR"
elif need python3; then
  python3 -m zipfile -e "$TMP_DIR/skillweb-skill.zip" "$CLAUDE_SKILLS_DIR"
elif need python; then
  python -m zipfile -e "$TMP_DIR/skillweb-skill.zip" "$CLAUDE_SKILLS_DIR"
else
  echo "error: need 'unzip' or 'python' to extract the skill archive." >&2
  exit 1
fi
set -e

if [ ! -f "$CLAUDE_SKILLS_DIR/skillweb/SKILL.md" ]; then
  echo "error: extraction did not produce ${CLAUDE_SKILLS_DIR}/skillweb/SKILL.md" >&2
  exit 1
fi

# Claude Code only auto-discovers .claude/skills/, but AGENTS.md (below) points
# non-Claude-Code agents at .agent/skills/skillweb — mirror the same content
# there too so that path is never a lie on the machine we just installed on.
mkdir -p "$AGENT_SKILLS_DIR"
rm -rf "$AGENT_SKILLS_DIR/skillweb"
cp -r "$CLAUDE_SKILLS_DIR/skillweb" "$AGENT_SKILLS_DIR/skillweb"

# Also drop AGENTS.md at the project root for non-Claude-Code agents (Codex CLI,
# opencode, Cursor, Aider, ...), without clobbering one the user already has.
AGENTS_DEST="${DEST_ROOT}/AGENTS.md"
if [ ! -f "$AGENTS_DEST" ]; then
  echo "→ Adding AGENTS.md (instructions for non-Claude-Code agents) ..."
  curl -fsSL "$AGENTS_URL" -o "$AGENTS_DEST" || echo "  (skipped — could not fetch AGENTS.md, not fatal)"
else
  echo "→ AGENTS.md already exists here — leaving it alone."
fi

echo ""
echo "✅ skillweb installed at ${CLAUDE_SKILLS_DIR}/skillweb (and mirrored at ${AGENT_SKILLS_DIR}/skillweb)"
echo ""
echo "Claude Code: restart your session (skills are scanned once at session start),"
echo "  then hand it a project .md and ask for a '발표자료'/web deck, or run /skillweb."
echo ""
echo "Other agents (Codex CLI, opencode, Cursor, Aider, ...): tell it to follow"
echo "  AGENTS.md at the project root, which points at .agent/skills/skillweb/SKILL.md."
