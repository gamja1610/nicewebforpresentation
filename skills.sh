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
SKILLS_DIR="${DEST_ROOT}/.claude/skills"

need() { command -v "$1" >/dev/null 2>&1; }

if ! need curl; then
  echo "error: curl is required but not found." >&2
  exit 1
fi

echo "→ Downloading skillweb-skill.zip from ${REPO}@${BRANCH} ..."
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
curl -fsSL "$ZIP_URL" -o "$TMP_DIR/skillweb-skill.zip"

mkdir -p "$SKILLS_DIR"

echo "→ Extracting into ${SKILLS_DIR}/skillweb ..."
# Note: the archive is built on Windows (PowerShell Compress-Archive), whose
# zip metadata makes Info-ZIP's unzip print a harmless "backslashes as path
# separators" warning and exit 1 even though extraction succeeds (entry names
# are plain forward-slash paths). So don't trust the extractor's exit code —
# turn off -e around it and verify the real result (SKILL.md landed) instead.
set +e
if need unzip; then
  unzip -oq "$TMP_DIR/skillweb-skill.zip" -d "$SKILLS_DIR"
elif need python3; then
  python3 -m zipfile -e "$TMP_DIR/skillweb-skill.zip" "$SKILLS_DIR"
elif need python; then
  python -m zipfile -e "$TMP_DIR/skillweb-skill.zip" "$SKILLS_DIR"
else
  echo "error: need 'unzip' or 'python' to extract the skill archive." >&2
  exit 1
fi
set -e

if [ ! -f "$SKILLS_DIR/skillweb/SKILL.md" ]; then
  echo "error: extraction did not produce ${SKILLS_DIR}/skillweb/SKILL.md" >&2
  exit 1
fi

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
echo "✅ skillweb installed at ${SKILLS_DIR}/skillweb"
echo ""
echo "Claude Code: restart your session (skills are scanned once at session start),"
echo "  then hand it a project .md and ask for a '발표자료'/web deck, or run /skillweb."
echo ""
echo "Other agents (Codex CLI, opencode, Cursor, Aider, ...): tell it to follow"
echo "  AGENTS.md at the project root, which points at .claude/skills/skillweb/SKILL.md."
