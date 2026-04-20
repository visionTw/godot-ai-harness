#!/bin/zsh
set -euo pipefail
setopt NULL_GLOB

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

echo "[Harness] Applying Cursor configuration..."
echo "  HARNESS_ROOT = $HARNESS_ROOT"
echo "  PROJECT_ROOT = $PROJECT_ROOT"

mkdir -p "$PROJECT_ROOT/.cursor/.npm-cache"
mkdir -p "$PROJECT_ROOT/.cursor/rules"
mkdir -p "$PROJECT_ROOT/.cursor/skills"
mkdir -p "$PROJECT_ROOT/.cursor/commands"
mkdir -p "$PROJECT_ROOT/.cursor/agents"

echo "[Harness] Cleaning previous harness artifacts (_harness_*) ..."
find "$PROJECT_ROOT/.cursor/rules" -maxdepth 1 -type f -name "_harness_*.mdc" -delete 2>/dev/null || true
find "$PROJECT_ROOT/.cursor/commands" -maxdepth 1 -type f -name "_harness_*.md" -delete 2>/dev/null || true
find "$PROJECT_ROOT/.cursor/agents" -maxdepth 1 -type f -name "_harness_*.md" -delete 2>/dev/null || true
find "$PROJECT_ROOT/.cursor/skills" -maxdepth 1 -type d -name "_harness_*" -exec rm -rf {} + 2>/dev/null || true

echo "[Harness] Syncing mcp.json ..."
cp -f "$HARNESS_ROOT/adapters/cursor/mcp.template.json" "$PROJECT_ROOT/.cursor/mcp.json"

rules_count=0
echo "[Harness] Syncing rules ..."
for f in "$HARNESS_ROOT/core/rules/"*.mdc; do
  [ -f "$f" ] || continue
  name="$(basename "$f")"
  case "$name" in
    _harness_*) cp -f "$f" "$PROJECT_ROOT/.cursor/rules/$name" ;;
    *)          cp -f "$f" "$PROJECT_ROOT/.cursor/rules/_harness_$name" ;;
  esac
  rules_count=$((rules_count + 1))
done
echo "  rules synced: $rules_count"

commands_count=0
echo "[Harness] Syncing commands ..."
for f in "$HARNESS_ROOT/core/commands/"*.md; do
  [ -f "$f" ] || continue
  cp -f "$f" "$PROJECT_ROOT/.cursor/commands/_harness_$(basename "$f")"
  commands_count=$((commands_count + 1))
done
echo "  commands synced: $commands_count"

agents_count=0
echo "[Harness] Syncing agents ..."
for f in "$HARNESS_ROOT/core/agents/"*.md; do
  [ -f "$f" ] || continue
  cp -f "$f" "$PROJECT_ROOT/.cursor/agents/_harness_$(basename "$f")"
  agents_count=$((agents_count + 1))
done
echo "  agents synced: $agents_count"

skills_count=0
echo "[Harness] Syncing skills ..."
if [ -d "$HARNESS_ROOT/core/skills" ]; then
  for d in "$HARNESS_ROOT/core/skills/"*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    target="$PROJECT_ROOT/.cursor/skills/_harness_$name"
    mkdir -p "$target"
    cp -R "$d." "$target/"
    skills_count=$((skills_count + 1))
  done
fi
echo "  skills synced: $skills_count"

echo
echo "[Harness] Cursor configuration applied for: $PROJECT_ROOT"
echo "  - .cursor/mcp.json"
echo "  - .cursor/rules/_harness_*.mdc"
echo "  - .cursor/commands/_harness_*.md"
echo "  - .cursor/agents/_harness_*.md"
echo "  - .cursor/skills/_harness_*/"
echo
echo "Next: open Cursor MCP panel and enable godot server."
