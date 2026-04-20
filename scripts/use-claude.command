#!/bin/zsh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HARNESS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="${PWD}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root)
      PROJECT_ROOT="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"

echo "[Harness] Applying ClaudeCode configuration..."
echo "  HARNESS_ROOT = $HARNESS_ROOT"
echo "  PROJECT_ROOT = $PROJECT_ROOT"

mkdir -p "$PROJECT_ROOT/.claude/agents"
mkdir -p "$PROJECT_ROOT/.claude/skills"
mkdir -p "$PROJECT_ROOT/.claude/commands"
mkdir -p "$PROJECT_ROOT/.claude/rules"

echo "[Harness] Cleaning previous harness artifacts (_harness_*) ..."
find "$PROJECT_ROOT/.claude/rules" -maxdepth 1 -type f -name "_harness_*.md" -delete 2>/dev/null || true
find "$PROJECT_ROOT/.claude/commands" -maxdepth 1 -type f -name "_harness_*.md" -delete 2>/dev/null || true
find "$PROJECT_ROOT/.claude/agents" -maxdepth 1 -type f -name "_harness_*.md" -delete 2>/dev/null || true
find "$PROJECT_ROOT/.claude/skills" -maxdepth 1 -type d -name "_harness_*" -exec rm -rf {} + 2>/dev/null || true

echo "[Harness] Syncing CLAUDE.md and mcp.json ..."
cp -f "$HARNESS_ROOT/adapters/claudecode/CLAUDE.template.md" "$PROJECT_ROOT/.claude/CLAUDE.md"
cp -f "$HARNESS_ROOT/adapters/claudecode/mcp.template.json" "$PROJECT_ROOT/.claude/mcp.json"

echo "[Harness] Syncing rules ..."
if compgen -G "$HARNESS_ROOT/core/rules/*.mdc" > /dev/null; then
  for f in "$HARNESS_ROOT/core/rules/"*.mdc; do
    base="$(basename "$f" .mdc)"
    cp -f "$f" "$PROJECT_ROOT/.claude/rules/_harness_${base}.md"
  done
fi

echo "[Harness] Syncing commands ..."
if compgen -G "$HARNESS_ROOT/core/commands/*.md" > /dev/null; then
  for f in "$HARNESS_ROOT/core/commands/"*.md; do
    cp -f "$f" "$PROJECT_ROOT/.claude/commands/_harness_$(basename "$f")"
  done
fi

echo "[Harness] Syncing agents ..."
if compgen -G "$HARNESS_ROOT/core/agents/*.md" > /dev/null; then
  for f in "$HARNESS_ROOT/core/agents/"*.md; do
    cp -f "$f" "$PROJECT_ROOT/.claude/agents/_harness_$(basename "$f")"
  done
fi

echo "[Harness] Syncing skills ..."
if [ -d "$HARNESS_ROOT/core/skills" ]; then
  for d in "$HARNESS_ROOT/core/skills/"*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    target="$PROJECT_ROOT/.claude/skills/_harness_$name"
    mkdir -p "$target"
    cp -R "$d." "$target/"
  done
fi

echo
echo "[Harness] ClaudeCode configuration applied for: $PROJECT_ROOT"
