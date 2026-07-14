#!/bin/bash
# Install claude-operating-principles into ~/.claude/
# Usage: bash install.sh [--project-slug <slug>]
# If --project-slug given, the memory file is copied into that project's
# memory directory. Otherwise only skills are installed (memory must be
# copied per-project manually).
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_SLUG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-slug) PROJECT_SLUG="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

# Install skills (iterate over the skills/ directory so this never drifts
# from what the repo actually ships)
echo "Installing skills to ~/.claude/skills/"
for dir in "$SCRIPT_DIR"/skills/*/; do
  skill="$(basename "$dir")"
  [ -f "$dir/SKILL.md" ] || continue
  mkdir -p "$HOME/.claude/skills/$skill"
  cp "$dir/SKILL.md" "$HOME/.claude/skills/$skill/SKILL.md"
  echo "  ✓ $skill"
done

# Install memory file if project slug given
if [[ -n "$PROJECT_SLUG" ]]; then
  PROJECT_MEM_DIR="$HOME/.claude/projects/$PROJECT_SLUG/memory"
  if [[ -d "$PROJECT_MEM_DIR" ]]; then
    cp "$SCRIPT_DIR/memory/principles_occam_operations.md" "$PROJECT_MEM_DIR/"
    echo "Memory file copied to: $PROJECT_MEM_DIR"
    echo ""
    echo "Add this line to $PROJECT_MEM_DIR/MEMORY.md (at the top):"
    echo "- [Occam-operations principles](principles_occam_operations.md) — Apply Occam's razor at the operational level: smallest reversible step first, pin source of truth, persistent concern catalog, delete before add, decision gate, verify subprocess reports, robust over clever; foundations-first (parity); triangulate load-bearing claims."
  else
    echo "Project memory dir not found: $PROJECT_MEM_DIR"
    echo "Copy memory/principles_occam_operations.md to the correct project memory dir manually."
  fi
else
  echo "(No --project-slug; skipping memory install. To install per-project memory:"
  echo "  cp memory/principles_occam_operations.md ~/.claude/projects/<slug>/memory/)"
fi

echo ""
echo "Done. Skills are now available via the Skill tool in any Claude Code session."
